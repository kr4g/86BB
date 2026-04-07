import { Client } from "node-osc";
import type { BioScores } from "../../shared/bioScoreTypes.js";
import { BIO_SCORE_NAMES } from "../../shared/bioScoreTypes.js";

let client: Client | null = null;

export function initOsc(port: number, host = "127.0.0.1"): void {
  client = new Client(host, port);
  console.log(`[OSC] Client ready → ${host}:${port}`);
}

function send(address: string, ...args: number[]): void {
  if (!client) return;
  client.send(address, ...args, () => {});
}

export function sendDigest(active: BioScores, impulseMagnitude: number): void {
  const vals = BIO_SCORE_NAMES.map((k) => active[k]);
  send("/86bb/digest", ...vals, impulseMagnitude);
}

export function sendStable(stable: BioScores): void {
  const vals = BIO_SCORE_NAMES.map((k) => stable[k]);
  send("/86bb/stable", ...vals);
}

export function sendBatchProgress(progress: number): void {
  send("/86bb/batch-progress", progress);
}
