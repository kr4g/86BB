export type MicrobeId =
  | "lRhamnosus"
  | "bLongum"
  | "lPlantarum"
  | "bInfantis"
  | "eFaecalis"
  | "sThermophilus"
  | "lAcidophilus"
  | "lReuteri"
  | "bFragilis"
  | "fPrausnitzii"
  | "rIntestinalis"
  | "aMuciniphila"
  | "pCopri"
  | "cSporogenes"
  | "eColiCommensal";

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

export type MicrobiomeProfile = Partial<Record<MicrobeId, number>>;

export interface FoodItem {
  id: string;
  name: string;
  category: FoodCategory;
  pixels: string[];
  displayWeight: number;
  microbiomeProfile: MicrobiomeProfile;
}

export interface MicrobeInfo {
  id: MicrobeId;
  name: string;
  shortName: string;
  role: string;
  neurotransmitters: string[];
  moodAssociations: string[];
}

export type GutState = Record<MicrobeId, number>;

export interface NeurotransmitterLevels {
  gaba: number;
  serotonin: number;
  dopamine: number;
  acetylcholine: number;
  butyrate: number;
  oxytocin: number;
}

export type NeurotransmitterId = keyof NeurotransmitterLevels;

export interface GutStateSnapshot {
  microbes: GutState;
  neurotransmitters: NeurotransmitterLevels;
  moodSummary: string;
  totalOrders: number;
  lastOrderTimestamp: string;
  createdAt: string;
}

export interface SelectionRequest {
  foodId: string;
}

export interface MicrobeChange {
  microbeId: MicrobeId;
  microbeName: string;
  direction: "up" | "down";
  magnitude: number;
  role: string;
}

export interface SelectionResponse {
  impact: {
    topChanges: MicrobeChange[];
    moodSummary: string;
  };
  gutState: GutStateSnapshot;
}
