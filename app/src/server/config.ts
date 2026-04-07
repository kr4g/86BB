import {
  DEFAULT_PORT,
  DEFAULT_DATA_DIR,
  DEFAULT_BATCH_SIZE,
  DEFAULT_ALPHA_SLOW,
  DEFAULT_SENSITIVITY,
  DEFAULT_KICK_SCALE,
  DEFAULT_MAX_ALPHA,
  SC_OSC_PORT,
} from "../shared/constants.js";

function envFloat(key: string, fallback: number): number {
  const v = process.env[key];
  if (v === undefined) return fallback;
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : fallback;
}

function envInt(key: string, fallback: number): number {
  const v = process.env[key];
  if (v === undefined) return fallback;
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : fallback;
}

function envStr(key: string, fallback: string): string {
  return process.env[key] ?? fallback;
}

export const config = {
  port: envInt("PORT", DEFAULT_PORT),
  dataDir: envStr("DATA_DIR", DEFAULT_DATA_DIR),
  batchSize: envInt("BATCH_SIZE", DEFAULT_BATCH_SIZE),
  alphaSlow: envFloat("ALPHA_SLOW", DEFAULT_ALPHA_SLOW),
  sensitivity: envFloat("SENSITIVITY", DEFAULT_SENSITIVITY),
  kickScale: envFloat("KICK_SCALE", DEFAULT_KICK_SCALE),
  maxAlpha: envFloat("MAX_ALPHA", DEFAULT_MAX_ALPHA),
  oscPort: envInt("OSC_PORT", SC_OSC_PORT),
} as const;
