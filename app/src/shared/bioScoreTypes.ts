export const BIO_SCORE_NAMES = [
  "health",
  "butyrate",
  "GABA",
  "serotonin",
  "dopamine",
  "inflammation",
  "barrier",
  "diversity",
] as const;

export type BioScoreName = (typeof BIO_SCORE_NAMES)[number];

export type BioScores = Record<BioScoreName, number>;

export interface DigestEvent {
  timestamp: string;
  batchSize: number;
  impulseMagnitude: number;
  activeBioScores: BioScores;
  stableBioScores: BioScores;
}

export interface GutDynamicsSnapshot {
  stableGut: number[];
  stableBioScores: BioScores;
  activeBioScores: BioScores;
  batchFoodIds: string[];
  totalSelections: number;
  totalDigestions: number;
  lastSelectionTimestamp: string;
  lastDigestionTimestamp: string;
  createdAt: string;
}

export function zeroBioScores(): BioScores {
  return {
    health: 0,
    butyrate: 0,
    GABA: 0,
    serotonin: 0,
    dopamine: 0,
    inflammation: 0,
    barrier: 0,
    diversity: 0,
  };
}
