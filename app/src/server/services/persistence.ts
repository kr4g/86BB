import {
  readFileSync,
  writeFileSync,
  renameSync,
  appendFileSync,
  existsSync,
  mkdirSync,
} from "fs";
import path from "path";
import { config } from "../config.js";
import { ALL_MICROBE_IDS } from "../../shared/data/microbes.js";
import { BASELINE_MICROBE_LEVEL, GUT_STATE_FILE, ORDER_HISTORY_FILE } from "../../shared/constants.js";
import type { GutState, GutStateSnapshot, NeurotransmitterLevels } from "../../shared/types.js";

function ensureDataDir(): void {
  if (!existsSync(config.dataDir)) {
    mkdirSync(config.dataDir, { recursive: true });
  }
}

function gutStatePath(): string {
  return path.join(config.dataDir, GUT_STATE_FILE);
}

function orderHistoryPath(): string {
  return path.join(config.dataDir, ORDER_HISTORY_FILE);
}

export function createBaselineGutState(): GutStateSnapshot {
  const microbes = Object.fromEntries(
    ALL_MICROBE_IDS.map((id) => [id, BASELINE_MICROBE_LEVEL])
  ) as GutState;

  const neurotransmitters: NeurotransmitterLevels = {
    gaba: BASELINE_MICROBE_LEVEL,
    serotonin: BASELINE_MICROBE_LEVEL,
    dopamine: BASELINE_MICROBE_LEVEL,
    acetylcholine: BASELINE_MICROBE_LEVEL,
    butyrate: BASELINE_MICROBE_LEVEL,
    oxytocin: BASELINE_MICROBE_LEVEL,
  };

  return {
    microbes,
    neurotransmitters,
    moodSummary: "neutral",
    totalOrders: 0,
    lastOrderTimestamp: new Date().toISOString(),
    createdAt: new Date().toISOString(),
  };
}

function atomicWrite(filePath: string, data: string): void {
  const tmpPath = filePath + ".tmp";
  writeFileSync(tmpPath, data, "utf-8");
  renameSync(tmpPath, filePath);
}

export function loadGutState(): GutStateSnapshot {
  ensureDataDir();
  const filePath = gutStatePath();

  if (!existsSync(filePath)) {
    const baseline = createBaselineGutState();
    saveGutState(baseline);
    return baseline;
  }

  try {
    const raw = readFileSync(filePath, "utf-8");
    const parsed = JSON.parse(raw) as GutStateSnapshot;

    for (const id of ALL_MICROBE_IDS) {
      if (typeof parsed.microbes[id] !== "number") {
        throw new Error(`Missing or invalid microbe: ${id}`);
      }
    }

    return parsed;
  } catch (err) {
    console.warn("Corrupted gut-state.json, reinitializing to baseline:", err);
    const baseline = createBaselineGutState();
    saveGutState(baseline);
    return baseline;
  }
}

export function saveGutState(snapshot: GutStateSnapshot): void {
  ensureDataDir();
  atomicWrite(gutStatePath(), JSON.stringify(snapshot, null, 2) + "\n");
}

export function appendOrderHistory(entry: Record<string, unknown>): void {
  ensureDataDir();
  appendFileSync(orderHistoryPath(), JSON.stringify(entry) + "\n", "utf-8");
}
