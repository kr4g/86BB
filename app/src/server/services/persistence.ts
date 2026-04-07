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
import { GUT_STATE_FILE, ORDER_HISTORY_FILE } from "../../shared/constants.js";
import type { GutDynamicsSnapshot } from "../../shared/bioScoreTypes.js";

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

function atomicWrite(filePath: string, data: string): void {
  const tmpPath = filePath + ".tmp";
  writeFileSync(tmpPath, data, "utf-8");
  renameSync(tmpPath, filePath);
}

export function loadState(): GutDynamicsSnapshot | null {
  ensureDataDir();
  const filePath = gutStatePath();

  if (!existsSync(filePath)) return null;

  try {
    const raw = readFileSync(filePath, "utf-8");
    const parsed = JSON.parse(raw) as GutDynamicsSnapshot;

    if (
      !parsed.stableGut ||
      !Array.isArray(parsed.stableGut) ||
      !parsed.stableBioScores
    ) {
      console.warn("[Persistence] Invalid state format, starting fresh");
      return null;
    }

    return parsed;
  } catch {
    console.warn("[Persistence] Corrupted state file, starting fresh");
    return null;
  }
}

export function saveState(snapshot: GutDynamicsSnapshot): void {
  ensureDataDir();
  atomicWrite(gutStatePath(), JSON.stringify(snapshot, null, 2) + "\n");
}

export function appendOrderHistory(entry: Record<string, unknown>): void {
  ensureDataDir();
  appendFileSync(orderHistoryPath(), JSON.stringify(entry) + "\n", "utf-8");
}
