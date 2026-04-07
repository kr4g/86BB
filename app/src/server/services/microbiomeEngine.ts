import { config } from "../config.js";
import { CATALOG } from "../../shared/data/catalog.js";
import {
  ALL_MICROBE_IDS,
  MICROBE_MAP,
  NEUROTRANSMITTER_MICROBE_MAP,
  NEUROTRANSMITTER_MOODS,
  HEALTH_MARKER_MICROBES,
} from "../../shared/data/microbes.js";
import {
  loadGutState,
  saveGutState,
  appendOrderHistory,
} from "./persistence.js";
import type {
  MicrobeId,
  GutState,
  GutStateSnapshot,
  NeurotransmitterLevels,
  NeurotransmitterId,
  MicrobeChange,
  SelectionResponse,
} from "../../shared/types.js";

const FOOD_MAP = new Map(CATALOG.map((f) => [f.id, f]));

function sigmoid(x: number): number {
  return 1 / (1 + Math.exp(-x));
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function computeInfluence(foodId: string): Record<MicrobeId, number> {
  const influence = Object.fromEntries(
    ALL_MICROBE_IDS.map((id) => [id, 0]),
  ) as Record<MicrobeId, number>;

  const item = FOOD_MAP.get(foodId);
  if (!item) return influence;

  for (const microbeId of ALL_MICROBE_IDS) {
    influence[microbeId] = item.microbiomeProfile[microbeId] ?? 0;
  }

  return influence;
}

export function normalizeToSignal(
  influence: Record<MicrobeId, number>,
  currentState: GutState,
): Record<MicrobeId, number> {
  const signal = {} as Record<MicrobeId, number>;

  for (const id of ALL_MICROBE_IDS) {
    if (influence[id] === 0) {
      signal[id] = currentState[id];
    } else {
      signal[id] = sigmoid(influence[id] / config.normFactor);
    }
  }

  return signal;
}

export function blendIntoGutState(
  currentState: GutState,
  signal: Record<MicrobeId, number>,
): GutState {
  const newState = {} as GutState;

  for (const id of ALL_MICROBE_IDS) {
    const blended =
      (1 - config.alpha) * currentState[id] + config.alpha * signal[id];
    newState[id] = clamp(blended, 0, 1);
  }

  return newState;
}

export function computeNeurotransmitters(
  microbes: GutState,
): NeurotransmitterLevels {
  const levels = {} as NeurotransmitterLevels;

  for (const [nt, microbeIds] of Object.entries(NEUROTRANSMITTER_MICROBE_MAP)) {
    const sum = microbeIds.reduce((acc, id) => acc + microbes[id], 0);
    levels[nt as NeurotransmitterId] = sum / microbeIds.length;
  }

  return levels;
}

export function computeMoodSummary(
  neurotransmitters: NeurotransmitterLevels,
  microbes: GutState,
): string {
  const healthAvg =
    HEALTH_MARKER_MICROBES.reduce((sum, id) => sum + microbes[id], 0) /
    HEALTH_MARKER_MICROBES.length;

  const isDistressed = healthAvg < 0.42;

  const sorted = (
    Object.entries(neurotransmitters) as [NeurotransmitterId, number][]
  ).sort((a, b) => b[1] - a[1]);

  if (isDistressed) {
    const lowest = sorted.slice(-2);
    const moods = lowest.flatMap(([nt]) =>
      NEUROTRANSMITTER_MOODS[nt].low.slice(0, 1),
    );
    const unique = [...new Set(moods)];
    return unique.slice(0, 3).join(", ");
  }

  const topNts = sorted.slice(0, 3);
  const moods = topNts.flatMap(([nt]) =>
    NEUROTRANSMITTER_MOODS[nt].high.slice(0, 1),
  );
  const unique = [...new Set(moods)];
  return unique.slice(0, 3).join(", ");
}

function computeTopChanges(
  before: GutState,
  after: GutState,
  count: number,
): MicrobeChange[] {
  const changes: MicrobeChange[] = ALL_MICROBE_IDS.map((id) => {
    const diff = after[id] - before[id];
    const info = MICROBE_MAP[id];
    return {
      microbeId: id,
      microbeName: info.shortName,
      direction: (diff >= 0 ? "up" : "down") as "up" | "down",
      magnitude: Math.abs(diff),
      role: info.role,
    };
  }).sort((a, b) => b.magnitude - a.magnitude);

  return changes.slice(0, count);
}

export function processSelection(foodId: string): SelectionResponse {
  const snapshot = loadGutState();
  const gutBefore = { ...snapshot.microbes };

  const influence = computeInfluence(foodId);
  const signal = normalizeToSignal(influence, snapshot.microbes);
  const newMicrobes = blendIntoGutState(snapshot.microbes, signal);
  const neurotransmitters = computeNeurotransmitters(newMicrobes);
  const moodSummary = computeMoodSummary(neurotransmitters, newMicrobes);

  const newSnapshot: GutStateSnapshot = {
    microbes: newMicrobes,
    neurotransmitters,
    moodSummary,
    totalOrders: snapshot.totalOrders + 1,
    lastOrderTimestamp: new Date().toISOString(),
    createdAt: snapshot.createdAt,
  };

  saveGutState(newSnapshot);

  appendOrderHistory({
    timestamp: newSnapshot.lastOrderTimestamp,
    foodId,
    orderInfluence: influence,
    gutStateBefore: gutBefore,
    gutStateAfter: newMicrobes,
  });

  const topChanges = computeTopChanges(gutBefore, newMicrobes, 5);

  return {
    impact: { topChanges, moodSummary },
    gutState: newSnapshot,
  };
}
