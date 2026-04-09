import type { BioScores, GutDynamicsSnapshot } from "./bioScoreTypes.js";

export type FoodCategory =
  | "fermented"
  | "fruits"
  | "vegetables"
  | "grains"
  | "proteins"
  | "dairy"
  | "beverages"
  | "sweets"
  | "legumes"
  | "nuts_seeds";

export interface FoodItem {
  id: string;
  name: string;
  category: FoodCategory;
  pixels: string[];
  displayWeight: number;
}

export interface SelectionRequest {
  foodId: string;
}

export interface SelectionResponse {
  foodId: string;
  activeBioScores: BioScores;
  stableBioScores: BioScores;
  impulseMagnitude: number;
}

export type { BioScores, GutDynamicsSnapshot };
