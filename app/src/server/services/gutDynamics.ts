import { readFileSync } from "fs";
import path from "path";
import { config } from "../config.js";
import {
  N_SPECIES,
  SPECIES_LIST,
  HEALTH_DIRECTION,
  PATHWAY_INDICES,
} from "../../shared/data/bioScoreConfig.js";
import {
  type BioScores,
  type GutDynamicsSnapshot,
  zeroBioScores,
  BIO_SCORE_NAMES,
} from "../../shared/bioScoreTypes.js";
import { sendDigest, sendStable, sendBatchProgress } from "./oscClient.js";
import { loadState, saveState, appendOrderHistory } from "./persistence.js";

type FoodProfileMap = Map<string, Float64Array>;

function loadFoodProfiles(): FoodProfileMap {
  const csvPath = path.resolve(
    config.dataDir,
    "../analysis/outputs/food_species_profiles.csv",
  );
  const raw = readFileSync(csvPath, "utf-8");
  const lines = raw.trim().split("\n");
  const header = lines[0].split(",");
  const speciesOrder = header.slice(1);

  const indexMap = speciesOrder.map((s) => SPECIES_LIST.indexOf(s));

  const profiles: FoodProfileMap = new Map();
  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(",");
    const foodId = cols[0];
    const profile = new Float64Array(N_SPECIES);
    for (let j = 1; j < cols.length; j++) {
      const targetIdx = indexMap[j - 1];
      if (targetIdx >= 0) {
        profile[targetIdx] = parseFloat(cols[j]);
      }
    }
    profiles.set(foodId, profile);
  }

  return profiles;
}

function dot(a: Float64Array | readonly number[], b: Float64Array | readonly number[]): number {
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += a[i] * b[i];
  return sum;
}

function norm(a: Float64Array): number {
  return Math.sqrt(dot(a, a));
}

function meanAtIndices(vec: Float64Array, indices: readonly number[]): number {
  if (indices.length === 0) return 0;
  let sum = 0;
  for (const i of indices) sum += vec[i];
  return sum / indices.length;
}

function computeBioScores(gut: Float64Array): BioScores {
  const scores = zeroBioScores();
  scores.health = dot(gut, HEALTH_DIRECTION);
  scores.butyrate = meanAtIndices(gut, PATHWAY_INDICES.butyrate);
  scores.GABA = meanAtIndices(gut, PATHWAY_INDICES.GABA);
  scores.serotonin = meanAtIndices(gut, PATHWAY_INDICES.serotonin);
  scores.dopamine = meanAtIndices(gut, PATHWAY_INDICES.dopamine);
  scores.inflammation = meanAtIndices(gut, PATHWAY_INDICES.inflammation);
  scores.barrier = meanAtIndices(gut, PATHWAY_INDICES.barrier);

  let sumSq = 0;
  for (let i = 0; i < gut.length; i++) sumSq += gut[i] * gut[i];
  scores.diversity = Math.sqrt(sumSq / gut.length);

  return scores;
}

export class GutDynamicsEngine {
  private foodProfiles: FoodProfileMap;
  private stableGut: Float64Array;
  private batch: Float64Array[];
  private batchFoodIds: string[];
  private totalSelections: number;
  private totalDigestions: number;
  private lastSelectionTimestamp: string;
  private lastDigestionTimestamp: string;
  private createdAt: string;

  private stableBioScores: BioScores;
  private activeBioScores: BioScores;

  constructor() {
    console.log("[GutDynamics] Loading food profiles...");
    this.foodProfiles = loadFoodProfiles();
    console.log(`[GutDynamics] ${this.foodProfiles.size} food profiles loaded`);

    const saved = loadState();
    if (saved) {
      this.stableGut = new Float64Array(saved.stableGut);
      this.batchFoodIds = saved.batchFoodIds;
      this.totalSelections = saved.totalSelections;
      this.totalDigestions = saved.totalDigestions;
      this.lastSelectionTimestamp = saved.lastSelectionTimestamp;
      this.lastDigestionTimestamp = saved.lastDigestionTimestamp;
      this.createdAt = saved.createdAt;
      this.stableBioScores = saved.stableBioScores;
      this.activeBioScores = saved.activeBioScores;

      this.batch = [];
      for (const fid of this.batchFoodIds) {
        const p = this.foodProfiles.get(fid);
        if (p) this.batch.push(p);
      }

      console.log(
        `[GutDynamics] Restored: ${this.totalSelections} selections, ${this.totalDigestions} digestions`,
      );
    } else {
      this.stableGut = new Float64Array(N_SPECIES);
      this.batch = [];
      this.batchFoodIds = [];
      this.totalSelections = 0;
      this.totalDigestions = 0;
      this.lastSelectionTimestamp = new Date().toISOString();
      this.lastDigestionTimestamp = new Date().toISOString();
      this.createdAt = new Date().toISOString();
      this.stableBioScores = zeroBioScores();
      this.activeBioScores = zeroBioScores();
      console.log("[GutDynamics] Starting fresh");
    }
  }

  get validFoodIds(): Set<string> {
    return new Set(this.foodProfiles.keys());
  }

  addSelection(foodId: string): {
    batchProgress: number;
    digested: boolean;
    activeBioScores: BioScores;
    stableBioScores: BioScores;
    impulseMagnitude: number;
  } {
    const profile = this.foodProfiles.get(foodId);
    if (!profile) {
      return {
        batchProgress: this.batch.length / config.batchSize,
        digested: false,
        activeBioScores: this.activeBioScores,
        stableBioScores: this.stableBioScores,
        impulseMagnitude: 0,
      };
    }

    this.batch.push(profile);
    this.batchFoodIds.push(foodId);
    this.totalSelections++;
    this.lastSelectionTimestamp = new Date().toISOString();

    const progress = this.batch.length / config.batchSize;
    sendBatchProgress(progress);

    appendOrderHistory({
      timestamp: this.lastSelectionTimestamp,
      foodId,
      selectionNumber: this.totalSelections,
      batchProgress: progress,
    });

    if (this.batch.length >= config.batchSize) {
      return this.digest();
    }

    return {
      batchProgress: progress,
      digested: false,
      activeBioScores: this.activeBioScores,
      stableBioScores: this.stableBioScores,
      impulseMagnitude: 0,
    };
  }

  private digest(): {
    batchProgress: number;
    digested: boolean;
    activeBioScores: BioScores;
    stableBioScores: BioScores;
    impulseMagnitude: number;
  } {
    const batchMean = new Float64Array(N_SPECIES);
    for (const profile of this.batch) {
      for (let i = 0; i < N_SPECIES; i++) batchMean[i] += profile[i];
    }
    for (let i = 0; i < N_SPECIES; i++) batchMean[i] /= this.batch.length;

    const diff = new Float64Array(N_SPECIES);
    for (let i = 0; i < N_SPECIES; i++) diff[i] = batchMean[i] - this.stableGut[i];
    const dist = norm(diff);

    const sensitiveFactor = 1.0 + config.sensitivity * dist;
    const effectiveAlpha = Math.min(
      config.alphaSlow * sensitiveFactor,
      config.maxAlpha,
    );

    for (let i = 0; i < N_SPECIES; i++) {
      this.stableGut[i] =
        (1 - effectiveAlpha) * this.stableGut[i] +
        effectiveAlpha * batchMean[i];
    }

    const activeGut = new Float64Array(N_SPECIES);
    for (let i = 0; i < N_SPECIES; i++) {
      activeGut[i] =
        this.stableGut[i] + diff[i] * config.kickScale;
    }

    this.stableBioScores = computeBioScores(this.stableGut);
    this.activeBioScores = computeBioScores(activeGut);

    let impulseSumSq = 0;
    for (const k of BIO_SCORE_NAMES) {
      const d = this.activeBioScores[k] - this.stableBioScores[k];
      impulseSumSq += d * d;
    }
    const impulseMagnitude = Math.sqrt(impulseSumSq);

    this.totalDigestions++;
    this.lastDigestionTimestamp = new Date().toISOString();

    sendDigest(this.activeBioScores, impulseMagnitude);
    sendStable(this.stableBioScores);

    console.log(
      `[GutDynamics] Digest #${this.totalDigestions}: impulse=${impulseMagnitude.toFixed(3)}, alpha=${effectiveAlpha.toFixed(4)}, health_stable=${this.stableBioScores.health.toFixed(3)}`,
    );

    this.batch = [];
    this.batchFoodIds = [];

    this.save();

    return {
      batchProgress: 0,
      digested: true,
      activeBioScores: this.activeBioScores,
      stableBioScores: this.stableBioScores,
      impulseMagnitude,
    };
  }

  getSnapshot(): GutDynamicsSnapshot {
    return {
      stableGut: Array.from(this.stableGut),
      stableBioScores: { ...this.stableBioScores },
      activeBioScores: { ...this.activeBioScores },
      batchFoodIds: [...this.batchFoodIds],
      totalSelections: this.totalSelections,
      totalDigestions: this.totalDigestions,
      lastSelectionTimestamp: this.lastSelectionTimestamp,
      lastDigestionTimestamp: this.lastDigestionTimestamp,
      createdAt: this.createdAt,
    };
  }

  reset(): void {
    this.stableGut = new Float64Array(N_SPECIES);
    this.batch = [];
    this.batchFoodIds = [];
    this.totalSelections = 0;
    this.totalDigestions = 0;
    this.lastSelectionTimestamp = new Date().toISOString();
    this.lastDigestionTimestamp = new Date().toISOString();
    this.createdAt = new Date().toISOString();
    this.stableBioScores = zeroBioScores();
    this.activeBioScores = zeroBioScores();
    this.save();
    sendStable(this.stableBioScores);
    console.log("[GutDynamics] Reset to baseline");
  }

  private save(): void {
    saveState(this.getSnapshot());
  }
}
