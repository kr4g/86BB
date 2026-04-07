# Cluster A/V Preset Descriptions

Generated from PREDICT 1 metabolic data (Asnicar et al., Nature Medicine 2021), neuroactive pathway analysis (literature-based species-to-pathway mapping), and composite health scoring. Each cluster represents a region of gut microbiome space with distinct biological characteristics.

16 clusters derived from 39 diet archetypes (27 original + 12 expanded), 2,260 synthetic profiles, K-Means clustering with silhouette-optimized K.

---

## Cluster 0: Fermented Calm

### Biological Profile
This gut state is dominated by dairy-fermenting organisms -- *Streptococcus thermophilus* and *Bifidobacterium animalis* are the strongest species, both strongly associated with dairy intake. The profile shows moderate anti-inflammatory signaling (low fasting inflammation, suppressed pro-inflammatory species like *Clostridium bolteae*) and notably elevated GABA and tryptophan/serotonin pathway potential. The combination of high serotonin precursor activity with GABA-producing Bifidobacteria creates a neurochemical environment associated with mood stability and anxiolytic effects. The health score is solidly positive (+1.62), and dietary pattern alignment favors Mediterranean and healthy-plant indices.

The metabolic picture is one of reduced systemic inflammation and modestly favorable lipid handling. This is a gut that is actively producing calming neuroactive compounds while maintaining low inflammatory tone -- a state of quiet biological maintenance.

### Design Cues
- **Mood valence**: calm, warm, stable, slightly drowsy
- **Energy level**: low-to-moderate, steady, unhurried
- **Sensory metaphors**: warm milk, slow pulse, soft hum, gentle rocking, candlelight

### Key Data
- Health score: +1.616
- PCA position: (-2.57, 4.68, 10.09)
- Dominant metabolic signal: low inflammation, low adverse lipids
- Dominant neuroactive signal: high GABA, high tryptophan/serotonin
- Top species: S. thermophilus (dairy), B. animalis (dairy)

---

## Cluster 1: Deep Green Vitality

### Biological Profile
The healthiest cluster in the analysis (health score +2.97), dominated by raw plant-eating profiles. The species signature is a textbook portrait of a thriving, fiber-fueled gut: *Roseburia hominis*, *Agathobaculum butyriciproducens*, *Eubacterium eligens* -- all major butyrate producers that thrive on plant fiber. Meanwhile, pro-inflammatory species (*E. coli*, *Anaerotruncus colihominis*) are strongly suppressed. The butyrate/SCFA pathway score is the second highest of all clusters.

Metabolically, this cluster shows the strongest anti-inflammatory profile (lowest fasting inflammation score), the most favorable lipid handling, and strong alignment with every positive dietary index (hPDI, HFD, Mediterranean, HEI). The neurochemical signature is dominated by SCFA-mediated neuroprotection with moderate serotonin pathway support. This is a gut in a state of deep, well-nourished equilibrium -- not stimulated or excited, but profoundly well-regulated.

### Design Cues
- **Mood valence**: serene, grounded, expansive, clear
- **Energy level**: moderate, deeply steady, resilient
- **Sensory metaphors**: deep breathing, forest floor, slow tide, morning light through leaves, low resonance

### Key Data
- Health score: +2.969
- PCA position: (-13.18, 0.16, -1.43)
- Dominant metabolic signal: lowest inflammation, lowest adverse lipids
- Dominant neuroactive signal: very high butyrate/SCFA, suppressed dopamine/inflammatory
- Top species: R. hominis (nuts/fiber), A. butyriciproducens (nuts), E. eligens (vegetables)

---

## Cluster 2: Carnivore Dysbiosis

### Biological Profile
The most negative health score tied with cluster 3 (health -1.39), this gut is shaped by heavy animal-product consumption, specifically organ meats and miscellaneous animal foods. The dominant species -- *Clostridium saccharolyticum*, *Anaeromassilibacillus*, *Ruthenibacterium lactatiformans* -- are proteolytic fermenters that thrive on animal protein. Beneficial butyrate producers and GABA-producing Bifidobacteria are suppressed. The metabolic fingerprint shows elevated fasting inflammation, unfavorable lipid profiles, and poor alignment with every healthy dietary index.

The neuroactive signature is marked by elevated dopamine/catecholamine potential (via *E. coli* relatives in the proteolytic niche) and elevated pro-inflammatory signaling. This is a gut under metabolic stress -- high protein fermentation producing branched-chain fatty acids and potentially toxic metabolites like trimethylamine, with low SCFA buffering. The biological state suggests heightened sympathetic arousal paired with chronic low-grade inflammation.

### Design Cues
- **Mood valence**: tense, sharp, wired, restless
- **Energy level**: high but brittle, edgy
- **Sensory metaphors**: coiled spring, metallic taste, fluorescent flicker, dry heat, grinding

### Key Data
- Health score: -1.392
- PCA position: (14.30, -0.16, 2.95)
- Dominant metabolic signal: high inflammation, high adverse lipids
- Dominant neuroactive signal: elevated dopamine/catecholamine, high pro-inflammatory
- Top species: C. saccharolyticum (meat), Anaeromassilibacillus (meat-associated)

---

## Cluster 3: Processed Fog

### Biological Profile
Dominated by ultra-processed, high-sugar, and junk food profiles, this cluster features species that thrive on refined carbohydrates and simple sugars. *Clostridium leptum* (associated with sweets) and *Ruthenibacterium lactatiformans* (associated with processed foods) lead, while beneficial species like *B. animalis* and *Anaerostipes hadrus* are suppressed. The health score is strongly negative (-1.20).

Metabolically, this profile shows elevated inflammation, unfavorable lipid handling, and the worst dietary pattern alignment (high uPDI, low HEI, low Mediterranean score). The neuroactive picture is mixed -- low butyrate production, moderate GABA (from residual Bifidobacteria), and elevated pro-inflammatory signaling. This gut state is characterized by metabolic confusion: high caloric throughput with poor nutritional quality, leading to a state of inflamed sluggishness. The brain receives contradictory signals -- sugar-driven dopamine spikes against a backdrop of inflammatory malaise.

### Design Cues
- **Mood valence**: foggy, heavy, dulled, unsettled
- **Energy level**: fluctuating -- brief spikes, prolonged troughs
- **Sensory metaphors**: sugar crash, humid static, smeared edges, overcast sky, sticky residue

### Key Data
- Health score: -1.199
- PCA position: (13.10, 4.73, -0.32)
- Dominant metabolic signal: elevated inflammation, elevated adverse lipids
- Dominant neuroactive signal: elevated pro-inflammatory, low butyrate
- Top species: C. leptum (sweets), R. lactatiformans (processed foods)

---

## Cluster 4: Protein Baseline

### Biological Profile
A near-neutral health score (+0.05) marks this as the most metabolically ambivalent cluster. Shaped by carnivore, zero-carb, and keto diets, the species profile is dominated by protein-and-fat fermenters (*Clostridium sp. CAG_58*, *Bacteroides sp. CAG_144*, *Methanobrevibacter smithii*) with suppressed Bifidobacteria and oral streptococci. The metabolic fingerprint is remarkably flat -- neither strongly inflamed nor strongly protective.

The neuroactive signature shows suppressed GABA (lowest among all clusters, from depleted Bifidobacteria), low tryptophan/serotonin, and moderately suppressed pro-inflammatory species. This is a gut that is metabolically functional but neurochemically sparse -- adequate protein digestion and fat metabolism, but lacking the fiber-derived compounds (butyrate, GABA precursors) that support mood regulation. The biological state is one of functional neutrality: efficient but uninspired.

### Design Cues
- **Mood valence**: flat, neutral, detached, functional
- **Energy level**: steady but low-affect, mechanical
- **Sensory metaphors**: grey tone, still air, even surface, distant hum, matte texture

### Key Data
- Health score: +0.046
- PCA position: (6.37, -7.33, 2.25)
- Dominant metabolic signal: neutral across all categories
- Dominant neuroactive signal: lowest GABA, low serotonin, moderate butyrate
- Top species: Clostridium sp. CAG_58 (meat), Bacteroides sp. CAG_144 (oils)

---

## Cluster 5: Fiber Glow

### Biological Profile
The largest cluster (486 members) and the second-healthiest (+2.14), representing the broad basin of high-fiber, plant-forward diets across cultures. The species signature closely resembles Cluster 1 but at lower intensity: *Firmicutes bacterium CAG_95*, *Roseburia hominis*, *Eubacterium eligens*, and *Agathobaculum butyriciproducens* dominate, all butyrate producers associated with nuts, vegetables, and legumes. Pro-inflammatory species (*C. innocuum*, *C. symbiosum*, *E. coli*) are strongly suppressed.

The metabolic fingerprint shows strong anti-inflammatory effects, favorable lipid profiles, and the second-strongest dietary index alignment. The neuroactive profile features robust butyrate/SCFA production with moderate serotonin pathway support and strongly suppressed inflammatory/dopamine pathways. Where Cluster 1 is the extreme of this state, Cluster 5 is its comfortable, sustainable center -- the gut equivalent of steady aerobic fitness rather than peak athletic performance.

### Design Cues
- **Mood valence**: warm, centered, gently optimistic, present
- **Energy level**: moderate-to-high, sustained, reliable
- **Sensory metaphors**: warm glow, steady breathing, golden light, gentle current, open space

### Key Data
- Health score: +2.144
- PCA position: (-8.23, 2.15, -0.62)
- Dominant metabolic signal: strong anti-inflammatory, favorable lipids
- Dominant neuroactive signal: high butyrate/SCFA, suppressed pro-inflammatory
- Top species: F. bacterium CAG_95, R. hominis (nuts), E. eligens (vegetables)

---

## Cluster 6: Moderate Balance

### Biological Profile
This large cluster (334 members) represents diverse, moderate diets that balance plant and animal sources. The species profile is a scaled-down version of the healthy-plant clusters, with *Firmicutes bacterium CAG_95*, *Eubacterium eligens*, and *Roseburia hominis* present but at lower abundance. Pro-inflammatory species are modestly suppressed. Health score is positive but moderate (+1.23).

The metabolic fingerprint sits between the healthy clusters and neutral center, with mild anti-inflammatory effects and modest lipid benefits. Neuroactive pathways show moderate butyrate production, suppressed inflammation, but without the strong GABA or serotonin signals of the dairy or extreme-plant clusters. This is the gut state of a generally healthy, varied diet -- nothing extreme, nothing deficient. The biological character is one of quiet competence.

### Design Cues
- **Mood valence**: mild, pleasant, unfocused warmth, easy
- **Energy level**: moderate, unexceptional, comfortable
- **Sensory metaphors**: room temperature, ambient daylight, background texture, soft focus, gentle rhythm

### Key Data
- Health score: +1.230
- PCA position: (-2.49, 0.82, -1.24)
- Dominant metabolic signal: mildly anti-inflammatory
- Dominant neuroactive signal: moderate butyrate, suppressed inflammatory
- Top species: F. bacterium CAG_95, E. eligens (eggs), A. butyriciproducens (nuts)

---

## Cluster 7: Sweet Ambivalence

### Biological Profile
A small, distinctive cluster (69 members) dominated by fruit-juice-heavy consumption. The species profile is mixed: *Bifidobacterium pseudocatenulatum* (GABA producer, legume-associated) and *Streptococcus parasanguinis* (serotonin pathway) coexist with *Faecalibacterium prausnitzii* (butyrate, gut barrier). But the profile also shows suppressed *Clostridium sp. CAG_242* and elevated *Clostridium leptum* (sweets-associated).

The metabolic fingerprint is mildly anti-inflammatory with a slightly favorable overall profile, but the health score is only modestly positive (+0.41). The neuroactive picture is interesting: the strongest gut-barrier score among all clusters, moderate GABA, and moderate serotonin -- suggesting a gut that is protectively sealed but processing a mix of beneficial and empty calories. This is a transitional state -- the biology of a sweet tooth that hasn't yet tipped into dysfunction.

### Design Cues
- **Mood valence**: bright, slightly restless, sweet but thin
- **Energy level**: moderate, slightly anxious, effervescent
- **Sensory metaphors**: sugar crystallization, bright surface over depth, carbonated, iridescent film, quick pulse

### Key Data
- Health score: +0.405
- PCA position: (1.65, 4.50, -1.87)
- Dominant metabolic signal: mildly anti-inflammatory
- Dominant neuroactive signal: highest gut barrier, moderate GABA + serotonin
- Top species: B. pseudocatenulatum (GABA), S. parasanguinis (serotonin), F. prausnitzii (butyrate/barrier)

---

## Cluster 8: Ethanol Dissociation

### Biological Profile
Shaped almost entirely by alcohol-heavy consumption, this small cluster (53 members) has a unique species signature. *Lawsonibacter asaccharolyticus* (tea/coffee/alcohol-associated) dominates, alongside *Roseburia sp. CAG_309* and *Oscillibacter sp. PC13* -- species that appear tolerant of ethanol's antimicrobial effects. Meanwhile, *Haemophilus parainfluenzae* (one of the healthiest-ranked species) and *Clostridium symbiosum* (pro-inflammatory) are both suppressed.

The metabolic fingerprint is paradoxical: favorable HDL lipids (alcohol's known HDL-boosting effect) alongside moderate inflammation suppression, yet the health score is only modestly positive (+0.62). Butyrate production is moderate but GABA is the most suppressed of any cluster. The dietary pattern alignment is scrambled -- positive Mediterranean score (alcohol is part of Mediterranean diet) but negative HFD (low diversity). This gut is pharmacologically altered rather than nutritionally optimized: ethanol selects for tolerant species while suppressing normal community structure.

### Design Cues
- **Mood valence**: dissociated, loose, blurred, disinhibited
- **Energy level**: artificially elevated, wobbly, ungrounded
- **Sensory metaphors**: soft blur, slow drift, loss of edges, underwater echo, dissolved boundaries

### Key Data
- Health score: +0.622
- PCA position: (1.78, -15.77, -4.09)
- Dominant metabolic signal: favorable HDL, paradoxical lipid profile
- Dominant neuroactive signal: lowest GABA, moderate butyrate, suppressed inflammatory
- Top species: L. asaccharolyticus (alcohol), Roseburia sp. CAG_309 (alcohol)

---

## Cluster 9: Stimulant Clarity

### Biological Profile
Driven by tea/coffee-dominant consumption, this cluster features the striking dominance of *Lawsonibacter asaccharolyticus* (highest centroid value of any species in any cluster at 0.212) alongside butyrate producers like *Agathobaculum butyriciproducens* and *Roseburia hominis*. The suppression pattern is telling: pro-inflammatory *Clostridium innocuum*, *R. gnavus*, and *C. symbiosum* are strongly depleted, suggesting the polyphenol-rich tea/coffee environment is actively hostile to inflammatory commensals.

The metabolic fingerprint shows anti-inflammatory effects with moderate lipid benefits. The neuroactive signature combines solid butyrate production with the highest GABA score among non-dairy clusters and strong serotonin pathway activity. This gut state reflects the known prebiotic effects of coffee and tea polyphenols -- they selectively promote beneficial fermenters while suppressing inflammatory species. The result is a neurochemically rich state: anti-inflammatory protection plus active neuromodulator production.

### Design Cues
- **Mood valence**: alert, focused, clear, quietly energized
- **Energy level**: elevated but controlled, precise
- **Sensory metaphors**: sharp focus, clean lines, morning clarity, bright edge, crisp air

### Key Data
- Health score: +1.104
- PCA position: (-2.58, -4.29, 1.44)
- Dominant metabolic signal: anti-inflammatory, moderate lipid benefit
- Dominant neuroactive signal: high butyrate, high GABA, high serotonin, very low dopamine
- Top species: L. asaccharolyticus (tea/coffee), A. butyriciproducens (butyrate)

---

## Cluster 10: Egg-Fiber Paradox

### Biological Profile
A distinctive cluster dominated by egg-heavy diets, featuring an unusual combination of highly-ranked health species (*Eubacterium eligens* rank 21, *Firmicutes bacterium CAG_95* rank 10, *Oscillibacter sp. 57_20* rank 12) alongside suppressed Bifidobacteria (*B. catenulatum*, *B. longum*) and pro-inflammatory Clostridia. The health score is solidly positive (+2.00).

The metabolic fingerprint shows strong anti-inflammatory effects (third lowest inflammation score) despite the unusual dietary driver. The neuroactive profile features high butyrate production but the second-lowest GABA (from depleted Bifidobacteria) and moderate serotonin. This creates a neurochemical asymmetry: strong anti-inflammatory protection and SCFA neuroprotection, but reduced GABAergic calming. The result is a state of protective alertness -- biologically well-maintained but without the anxiolytic softness of the dairy or balanced clusters.

### Design Cues
- **Mood valence**: alert, awake, slightly on-edge, watchful
- **Energy level**: high, attentive, spring-loaded
- **Sensory metaphors**: dawn light, taut string, clear horizon, bright but cool, electric stillness

### Key Data
- Health score: +2.003
- PCA position: (-5.86, -8.36, 3.87)
- Dominant metabolic signal: strong anti-inflammatory
- Dominant neuroactive signal: high butyrate, very low GABA, moderate serotonin
- Top species: E. eligens (egg), F. bacterium CAG_95, F. bacterium CAG_170 (egg)

---

## Cluster 11: Starch Erosion

### Biological Profile
Shaped by potato-starch-heavy diets, this cluster shows a health-negative profile (-1.29) dominated by species associated with starch fermentation and processed foods: *Clostridium leptum*, *Ruthenibacterium lactatiformans*, *Alistipes finegoldii*, *Bacteroides uniformis*. Healthy butyrate producers (*Anaerostipes hadrus*, *Roseburia sp. CAG_182*) and dairy-associated Bifidobacteria are suppressed.

The metabolic fingerprint mirrors the other unhealthy clusters: elevated inflammation, unfavorable lipids, poor dietary pattern alignment. The neuroactive profile is mildly negative across all protective pathways (low butyrate, low GABA, low serotonin) with mildly elevated pro-inflammatory signaling. This gut state represents slow degradation -- the microbiome of monotonous starch consumption that gradually depletes diversity and protective species. The biological character is one of erosion rather than acute damage.

### Design Cues
- **Mood valence**: heavy, dull, resigned, slowly sinking
- **Energy level**: low, ponderous, inertial
- **Sensory metaphors**: settling sediment, overcast afternoon, thick air, slow decay, muffled sound

### Key Data
- Health score: -1.288
- PCA position: (12.27, 1.70, -5.29)
- Dominant metabolic signal: elevated inflammation, elevated adverse lipids
- Dominant neuroactive signal: low across all protective pathways
- Top species: C. leptum (sweets/starch), R. lactatiformans (processed), A. finegoldii (meat)

---

## Cluster 12: Cosmopolitan Center

### Biological Profile
The largest "normal" cluster (273 members), representing balanced, Italian, and Chinese urban diets. The species profile is the most evenly distributed of any cluster -- no species has extreme values. *Firmicutes bacterium CAG_95* (highly health-ranked) leads modestly, with mild butyrate producer presence (*Roseburia sp. CAG_309*) and mild pro-inflammatory suppression. Health score is modestly positive (+0.63).

The metabolic and neuroactive fingerprints are near-zero across all axes -- this is the mathematical center of gut-state space. Every pathway is mildly active, nothing is strongly activated or suppressed. This cluster represents the statistical average gut -- the most common state a moderately varied diet produces. Its biological character is defined by its lack of strong features: neither inflamed nor protected, neither neurochemically rich nor depleted.

### Design Cues
- **Mood valence**: neutral, unremarkable, centered, present
- **Energy level**: baseline, steady, ordinary
- **Sensory metaphors**: still water, grey-white noise, room tone, midday, flat horizon

### Key Data
- Health score: +0.633
- PCA position: (1.97, -1.97, 0.16)
- Dominant metabolic signal: near-neutral across all categories
- Dominant neuroactive signal: mild across all pathways
- Top species: F. bacterium CAG_95, Oscillibacter sp. PC13, Flavonifractor sp. An100

---

## Cluster 13: Industrial Decline

### Biological Profile
The classic Western processed-food microbiome: British pub, US fast food, and Western processed diets dominate. The species profile features proteolytic and starch-fermenting Clostridia (*C. leptum*, *R. lactatiformans*, *C. saccharolyticum*) while healthy-ranked species like *Haemophilus parainfluenzae* (rank 10) and butyrate-producing *Roseburia sp. CAG_182* (rank 15) are suppressed. Health score is solidly negative (-1.12).

The metabolic fingerprint shows elevated inflammation, unfavorable lipids, and strong misalignment with all healthy dietary indices. The neuroactive profile features suppressed butyrate, suppressed GABA, suppressed serotonin, and elevated pro-inflammatory species. This is the most comprehensively degraded neuroactive profile -- every protective pathway is diminished while every inflammatory pathway is elevated. The biological state is one of chronic, smoldering dysfunction -- the microbiome signature of industrialized eating.

### Design Cues
- **Mood valence**: irritable, fatigued, inflamed, restless
- **Energy level**: low with agitated undertone, depleted
- **Sensory metaphors**: fluorescent buzz, stale air, rumble, corrosion, low-frequency pressure

### Key Data
- Health score: -1.122
- PCA position: (13.11, -1.43, -0.44)
- Dominant metabolic signal: elevated inflammation, unfavorable lipids
- Dominant neuroactive signal: suppressed all protective, elevated inflammatory
- Top species: C. leptum (sweets), F. bacterium CAG_94, R. lactatiformans (processed)

---

## Cluster 14: Peak Nourishment

### Biological Profile
The single healthiest cluster in the entire analysis (health score +3.58), representing the extreme of nut-seed-dominant diets. The species signature is the most strongly polarized: *Roseburia hominis*, *Agathobaculum butyriciproducens*, *Oscillibacter sp. 57_20*, *Eubacterium hallii* -- all major butyrate and SCFA producers -- at their highest centroid values of any cluster. Conversely, pro-inflammatory species (*C. symbiosum*, *Anaerotruncus colihominis*) and protein-fermenting *Ruthenibacterium lactatiformans* are at their most suppressed.

Every metabolic marker is at its extreme: the lowest inflammation, the lowest adverse lipid scores, the strongest anti-inflammatory postprandial response, and perfect alignment with all healthy dietary indices. The butyrate/SCFA pathway score is the absolute highest. This is the theoretical peak of gut health as defined by the PREDICT 1 data -- a state of maximal SCFA production, maximal inflammation suppression, and maximal neuroprotection. It represents an extreme that few real-world diets achieve sustainably.

### Design Cues
- **Mood valence**: radiant, expansive, deeply calm, luminous
- **Energy level**: high but serene, effortless vitality
- **Sensory metaphors**: sunlight through water, deep resonance, open sky, crystalline clarity, slow bloom

### Key Data
- Health score: +3.575
- PCA position: (-17.64, -2.13, -0.87)
- Dominant metabolic signal: extreme anti-inflammatory, most favorable lipids
- Dominant neuroactive signal: highest butyrate/SCFA, highest serotonin, lowest dopamine/inflammatory
- Top species: R. hominis (nuts), A. butyriciproducens (nuts), O. sp. 57_20 (nuts), E. hallii (nuts)

---

## Cluster 15: Margarine Malaise

### Biological Profile
Shaped by margarine and processed-fat-heavy diets, this small cluster (60 members) features a species profile similar to the other unhealthy clusters but with a distinctive bias: *Clostridium leptum* (sweets-associated) and *Dialister invisus* (sweets/refined grains) dominate, while dairy-associated Bifidobacteria and *Streptococcus thermophilus* are suppressed. The health score is moderately negative (-0.92).

The metabolic fingerprint shows elevated inflammation and unfavorable lipid profiles, with poor dietary pattern alignment. The neuroactive profile is mildly depleted across protective pathways with slightly elevated pro-inflammatory signaling. This gut state represents the consequences of a diet dominated by industrial fats -- trans fats and refined seed oils that alter membrane composition and selectively promote fat-tolerant, health-negative species. The biological character is one of quiet metabolic distortion.

### Design Cues
- **Mood valence**: uneasy, slightly nauseous, off-kilter, drained
- **Energy level**: low, sluggish, vaguely uncomfortable
- **Sensory metaphors**: greasy film, yellowish light, low haze, slightly off-pitch, thick texture

### Key Data
- Health score: -0.920
- PCA position: (10.57, 7.71, -3.00)
- Dominant metabolic signal: elevated inflammation, elevated adverse lipids
- Dominant neuroactive signal: mildly depleted protective, mildly elevated inflammatory
- Top species: C. leptum (sweets), F. bacterium CAG_94, R. lactatiformans (processed)
