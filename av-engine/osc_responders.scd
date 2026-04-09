// OSC responders for 86BB gut dynamics → SuperCollider A/V engine.

(
var bioNames = #[\health, \butyrate, \GABA, \serotonin, \dopamine, \inflammation, \barrier, \diversity];
var nScores = bioNames.size;
var decayRate = 0.03;

~stable = 0.dup(nScores);
~active = 0.dup(nScores);
~impulse = 0.0;
~batchProgress = 0.0;

~clusterLabels = [
	"Fermented Calm", "Deep Green Vitality", "Carnivore Dysbiosis",
	"Processed Fog", "Protein Baseline", "Fiber Glow",
	"Moderate Balance", "Sweet Ambivalence", "Ethanol Dissociation",
	"Stimulant Clarity", "Egg-Fiber Paradox", "Starch Erosion",
	"Cosmopolitan Center", "Industrial Decline", "Peak Nourishment",
	"Margarine Malaise",
];

~clusterBioScores = [
	[1.616309, 0.007825, 0.012614, 0.033224, -0.044920, -0.036500, 0.004111, 0.020000],
	[2.968822, 0.050739, -0.006722, 0.028812, -0.082677, -0.061872, -0.004450, 0.020000],
	[-1.392084, -0.024678, -0.006939, -0.018756, 0.016092, 0.023982, -0.000105, 0.020000],
	[-1.199081, -0.013775, 0.007038, -0.004628, 0.018074, 0.024374, 0.019303, 0.020000],
	[0.046171, 0.007371, -0.021478, -0.002264, -0.012126, -0.002151, -0.006146, 0.020000],
	[2.144075, 0.033875, -0.001874, 0.024487, -0.062407, -0.046072, 0.000483, 0.020000],
	[1.230090, 0.020699, -0.007017, 0.011486, -0.039205, -0.027800, -0.001010, 0.020000],
	[0.405420, 0.009680, 0.008364, 0.014068, -0.008186, -0.014058, 0.016614, 0.020000],
	[0.621813, 0.026589, -0.022841, -0.000907, -0.032691, -0.033087, -0.007303, 0.020000],
	[1.103650, 0.031361, 0.011334, 0.027154, -0.057358, -0.044616, 0.017968, 0.020000],
	[2.002967, 0.032072, -0.022993, 0.016630, -0.031982, -0.044379, -0.010227, 0.020000],
	[-1.287904, -0.013880, -0.004045, -0.022882, 0.009365, 0.021316, 0.001288, 0.020000],
	[0.632846, 0.012880, -0.007643, 0.007383, -0.025221, -0.017881, 0.000046, 0.020000],
	[-1.122469, -0.010977, -0.006037, -0.010541, 0.013244, 0.020432, 0.006132, 0.020000],
	[3.575391, 0.062743, -0.011195, 0.037179, -0.106623, -0.080681, -0.007437, 0.020000],
	[-0.919719, -0.017040, 0.002132, -0.011222, 0.010226, 0.016658, 0.000232, 0.020000],
];

~findNearestClusters = { |vec|
	var dists = ~clusterBioScores.collect({ |cv|
		var sum = 0;
		nScores.do { |i| sum = sum + ((vec[i] - cv[i]).squared) };
		sum.sqrt;
	});
	var sorted = (0..15).sort({ |a, b| dists[a] < dists[b] });
	[sorted[0], dists[sorted[0]], sorted[1], dists[sorted[1]]];
};

OSCdef(\digest, { |msg|
	var nearest;
	nScores.do { |i| ~active[i] = msg[i + 1].asFloat };
	~impulse = msg[nScores + 1].asFloat;

	~predictFromBioScores.(~active);

	nearest = ~findNearestClusters.(~active);
	("").postln;
	("[86BB] ═══ DIGEST ═══").postln;
	("[86BB]   impulse: " ++ ~impulse.round(0.001)).postln;
	("[86BB]   health:  " ++ ~active[0].round(0.001)
		++ "  butyrate: " ++ ~active[1].round(0.0001)
		++ "  GABA: " ++ ~active[2].round(0.0001)).postln;
	("[86BB]   serotonin: " ++ ~active[3].round(0.0001)
		++ "  dopamine: " ++ ~active[4].round(0.0001)
		++ "  inflam: " ++ ~active[5].round(0.0001)).postln;
	("[86BB]   nearest: C" ++ nearest[0] ++ " " ++ ~clusterLabels[nearest[0]]
		++ " (d=" ++ nearest[1].round(0.01) ++ ")").postln;
	("[86BB]   2nd:     C" ++ nearest[2] ++ " " ++ ~clusterLabels[nearest[2]]
		++ " (d=" ++ nearest[3].round(0.01) ++ ")").postln;
}, '/86bb/digest');

OSCdef(\stable, { |msg|
	var nearest;
	nScores.do { |i| ~stable[i] = msg[i + 1].asFloat };
	nearest = ~findNearestClusters.(~stable);
	("[86BB]   stable → C" ++ nearest[0] ++ " " ++ ~clusterLabels[nearest[0]]
		++ " (health=" ++ ~stable[0].round(0.001) ++ ")").postln;
}, '/86bb/stable');

OSCdef(\batchProgress, { |msg|
	~batchProgress = msg[1].asFloat;
	("[86BB]   batch: " ++ (~batchProgress * 100).round(1) ++ "%").postln;
}, '/86bb/batch-progress');

~decayRoutine.stop;
~decayRoutine = Routine({
	var predCounter = 0;
	inf.do {
		nScores.do { |i|
			~active[i] = ~active[i] + ((~stable[i] - ~active[i]) * decayRate);
		};

		predCounter = predCounter + 1;
		if(predCounter >= 10, {
			~predictFromBioScores.(~active);
			predCounter = 0;
		});

		(1/30).wait;
	};
}).play(SystemClock);

"[86BB] OSC responders registered (digest, stable, batch-progress, decay+predict @30fps).".postln;
)
