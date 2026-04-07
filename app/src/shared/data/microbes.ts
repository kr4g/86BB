import type { MicrobeInfo, MicrobeId, NeurotransmitterId } from "../types.js";

export const MICROBES: MicrobeInfo[] = [
  {
    id: "lRhamnosus",
    name: "Lactobacillus rhamnosus",
    shortName: "L. rhamnosus",
    role: "lactic acid producer, gut lining support",
    neurotransmitters: ["GABA"],
    moodAssociations: ["calm", "anxiety reduction"],
  },
  {
    id: "bLongum",
    name: "Bifidobacterium longum",
    shortName: "B. longum",
    role: "fiber fermenter, vitamin synthesis",
    neurotransmitters: ["GABA", "serotonin"],
    moodAssociations: ["mood stability", "stress resilience"],
  },
  {
    id: "lPlantarum",
    name: "Lactobacillus plantarum",
    shortName: "L. plantarum",
    role: "antimicrobial peptide producer",
    neurotransmitters: ["acetylcholine", "GABA"],
    moodAssociations: ["focus", "calm"],
  },
  {
    id: "bInfantis",
    name: "Bifidobacterium infantis",
    shortName: "B. infantis",
    role: "tryptophan metabolism",
    neurotransmitters: ["serotonin"],
    moodAssociations: ["emotional balance"],
  },
  {
    id: "eFaecalis",
    name: "Enterococcus faecalis",
    shortName: "E. faecalis",
    role: "serotonin precursor synthesis",
    neurotransmitters: ["serotonin"],
    moodAssociations: ["contentment"],
  },
  {
    id: "sThermophilus",
    name: "Streptococcus thermophilus",
    shortName: "S. thermophilus",
    role: "lactose digestion, lactic acid production",
    neurotransmitters: ["serotonin"],
    moodAssociations: ["well-being"],
  },
  {
    id: "lAcidophilus",
    name: "Lactobacillus acidophilus",
    shortName: "L. acidophilus",
    role: "lactic acid producer, pathogen inhibitor",
    neurotransmitters: ["serotonin"],
    moodAssociations: ["mood elevation"],
  },
  {
    id: "lReuteri",
    name: "Lactobacillus reuteri",
    shortName: "L. reuteri",
    role: "histamine modulator, immune signaling",
    neurotransmitters: ["oxytocin"],
    moodAssociations: ["social bonding", "trust"],
  },
  {
    id: "bFragilis",
    name: "Bacteroides fragilis",
    shortName: "B. fragilis",
    role: "polysaccharide digestion",
    neurotransmitters: ["GABA"],
    moodAssociations: ["calm", "inhibition"],
  },
  {
    id: "fPrausnitzii",
    name: "Faecalibacterium prausnitzii",
    shortName: "F. prausnitzii",
    role: "butyrate producer, anti-inflammatory",
    neurotransmitters: ["butyrate"],
    moodAssociations: ["anti-inflammation", "equilibrium"],
  },
  {
    id: "rIntestinalis",
    name: "Roseburia intestinalis",
    shortName: "R. intestinalis",
    role: "butyrate producer, fiber fermenter",
    neurotransmitters: ["butyrate"],
    moodAssociations: ["gut-brain integrity"],
  },
  {
    id: "aMuciniphila",
    name: "Akkermansia muciniphila",
    shortName: "A. muciniphila",
    role: "mucin layer maintenance",
    neurotransmitters: [],
    moodAssociations: ["metabolic balance"],
  },
  {
    id: "pCopri",
    name: "Prevotella copri",
    shortName: "P. copri",
    role: "complex carbohydrate metabolism",
    neurotransmitters: [],
    moodAssociations: ["energy regulation"],
  },
  {
    id: "cSporogenes",
    name: "Clostridium sporogenes",
    shortName: "C. sporogenes",
    role: "tryptamine producer",
    neurotransmitters: ["serotonin"],
    moodAssociations: ["arousal", "alertness"],
  },
  {
    id: "eColiCommensal",
    name: "Escherichia coli (commensal)",
    shortName: "E. coli",
    role: "catecholamine synthesis, vitamin K production",
    neurotransmitters: ["dopamine", "norepinephrine"],
    moodAssociations: ["motivation", "alertness"],
  },
];

export const MICROBE_MAP = Object.fromEntries(
  MICROBES.map((m) => [m.id, m])
) as Record<MicrobeId, MicrobeInfo>;

export const ALL_MICROBE_IDS: MicrobeId[] = MICROBES.map((m) => m.id);

export const NEUROTRANSMITTER_MICROBE_MAP: Record<NeurotransmitterId, MicrobeId[]> = {
  gaba: ["lRhamnosus", "bLongum", "lPlantarum", "bFragilis"],
  serotonin: ["bLongum", "bInfantis", "eFaecalis", "sThermophilus", "lAcidophilus", "cSporogenes"],
  dopamine: ["eColiCommensal"],
  acetylcholine: ["lPlantarum"],
  butyrate: ["fPrausnitzii", "rIntestinalis"],
  oxytocin: ["lReuteri"],
};

export const NEUROTRANSMITTER_LABELS: Record<NeurotransmitterId, string> = {
  gaba: "GABA",
  serotonin: "Serotonin",
  dopamine: "Dopamine",
  acetylcholine: "Acetylcholine",
  butyrate: "Butyrate",
  oxytocin: "Oxytocin",
};

export const NEUROTRANSMITTER_MOODS: Record<NeurotransmitterId, { high: string[]; low: string[] }> = {
  gaba: { high: ["calm", "anxiety reduction"], low: ["anxious", "restless"] },
  serotonin: { high: ["contentment", "well-being"], low: ["low mood", "irritable"] },
  dopamine: { high: ["motivation", "reward"], low: ["apathetic", "sluggish"] },
  acetylcholine: { high: ["focus", "cognition"], low: ["foggy", "distracted"] },
  butyrate: { high: ["gut-brain health", "equilibrium"], low: ["inflamed", "disrupted"] },
  oxytocin: { high: ["social bonding", "trust"], low: ["withdrawn", "disconnected"] },
};

export const DYSBIOSIS_MICROBES: MicrobeId[] = ["eColiCommensal", "bFragilis", "cSporogenes"];
export const HEALTH_MARKER_MICROBES: MicrobeId[] = ["fPrausnitzii", "aMuciniphila", "bLongum", "rIntestinalis"];

export const MICROBE_MOOD_BY_DIRECTION: Record<MicrobeId, { up: string; down: string }> = {
  lRhamnosus:     { up: "calm",              down: "anxiety" },
  bLongum:        { up: "mood stability",    down: "low mood" },
  lPlantarum:     { up: "focus",             down: "brain fog" },
  bInfantis:      { up: "emotional balance", down: "irritability" },
  eFaecalis:      { up: "contentment",       down: "unease" },
  sThermophilus:   { up: "well-being",        down: "discomfort" },
  lAcidophilus:   { up: "mood elevation",    down: "flatness" },
  lReuteri:       { up: "social bonding",    down: "withdrawal" },
  bFragilis:      { up: "calm",              down: "restlessness" },
  fPrausnitzii:   { up: "equilibrium",       down: "inflammation" },
  rIntestinalis:  { up: "gut integrity",     down: "disruption" },
  aMuciniphila:   { up: "metabolic balance", down: "imbalance" },
  pCopri:         { up: "energy",            down: "fatigue" },
  cSporogenes:    { up: "alertness",         down: "dullness" },
  eColiCommensal: { up: "motivation",        down: "overstimulation" },
};
