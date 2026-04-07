import {
  DEFAULT_ALPHA,
  DEFAULT_NORM_FACTOR,
  DEFAULT_PORT,
  DEFAULT_DATA_DIR,
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
  alpha: envFloat("ALPHA", DEFAULT_ALPHA),
  normFactor: envFloat("NORM_FACTOR", DEFAULT_NORM_FACTOR),
  port: envInt("PORT", DEFAULT_PORT),
  dataDir: envStr("DATA_DIR", DEFAULT_DATA_DIR),
} as const;
