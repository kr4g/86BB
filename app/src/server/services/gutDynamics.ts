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
import { sendDigest, sendStable } from "./oscClient.js";
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
  private totalSelections: number;
  private lastSelectionTimestamp: string;
  private createdAt: string;
  private saveCounter: number;

  private stableBioScores: BioScores;
  private activeBioScores: BioScores;

  constructor() {
    console.log("[GutDynamics] Loading food profiles...");
    this.foodProfiles = loadFoodProfiles();
    console.log(`[GutDynamics] ${this.foodProfiles.size} food profiles loaded`);

    this.saveCounter = 0;

    const saved = loadState();
    if (saved) {
      this.stableGut = new Float64Array(saved.stableGut);
      this.totalSelections = saved.totalSelections;
      this.lastSelectionTimestamp = saved.lastSelectionTimestamp;
      this.createdAt = saved.createdAt;
      this.stableBioScores = saved.stableBioScores;
      this.activeBioScores = saved.activeBioScores;
      console.log(
        `[GutDynamics] Restored: ${this.totalSelections} selections`,
      );
    } else {
      this.stableGut = new Float64Array(N_SPECIES);
      this.totalSelections = 0;
      this.lastSelectionTimestamp = new Date().toISOString();
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
    activeBioScores: BioScores;
    stableBioScores: BioScores;
    impulseMagnitude: number;
  } {
    const profile = this.foodProfiles.get(foodId);
    if (!profile) {
      return {
        activeBioScores: this.activeBioScores,
        stableBioScores: this.stableBioScores,
        impulseMagnitude: 0,
      };
    }

    this.totalSelections++;
    this.lastSelectionTimestamp = new Date().toISOString();

    const diff = new Float64Array(N_SPECIES);
    for (let i = 0; i < N_SPECIES; i++) diff[i] = profile[i] - this.stableGut[i];
    const dist = norm(diff);

    const sensitiveFactor = 1.0 + config.sensitivity * dist;
    const effectiveAlpha = Math.min(
      config.alphaSlow * sensitiveFactor,
      config.maxAlpha,
    );

    for (let i = 0; i < N_SPECIES; i++) {
      this.stableGut[i] =
        (1 - effectiveAlpha) * this.stableGut[i] +
        effectiveAlpha * profile[i];
    }

    const activeGut = new Float64Array(N_SPECIES);
    for (let i = 0; i < N_SPECIES; i++) {
      activeGut[i] = this.stableGut[i] + diff[i] * config.kickScale;
    }

    this.stableBioScores = computeBioScores(this.stableGut);
    this.activeBioScores = computeBioScores(activeGut);

    let impulseSumSq = 0;
    for (const k of BIO_SCORE_NAMES) {
      const d = this.activeBioScores[k] - this.stableBioScores[k];
      impulseSumSq += d * d;
    }
    const impulseMagnitude = Math.sqrt(impulseSumSq);

    sendDigest(this.activeBioScores, impulseMagnitude);
    sendStable(this.stableBioScores);

    console.log(
      `[GutDynamics] #${this.totalSelections} ${foodId}: impulse=${impulseMagnitude.toFixed(3)}, alpha=${effectiveAlpha.toFixed(4)}, health=${this.stableBioScores.health.toFixed(3)}`,
    );

    appendOrderHistory({
      timestamp: this.lastSelectionTimestamp,
      foodId,
      selectionNumber: this.totalSelections,
    });

    this.saveCounter++;
    if (this.saveCounter >= 5) {
      this.save();
      this.saveCounter = 0;
    }

    return {
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
      batchFoodIds: [],
      totalSelections: this.totalSelections,
      totalDigestions: this.totalSelections,
      lastSelectionTimestamp: this.lastSelectionTimestamp,
      lastDigestionTimestamp: this.lastSelectionTimestamp,
      createdAt: this.createdAt,
    };
  }

  reset(): void {
    this.stableGut = new Float64Array(N_SPECIES);
    this.totalSelections = 0;
    this.lastSelectionTimestamp = new Date().toISOString();
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
