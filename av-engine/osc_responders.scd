// OSC responders for 86BB gut dynamics → SuperCollider A/V engine.
// Express sends bio-score vectors on digestion events;
// SC decays the active state toward stable between events.

(
var bioNames = #[\health, \butyrate, \GABA, \serotonin, \dopamine, \inflammation, \barrier, \diversity];
var nScores = bioNames.size;
var decayRate = 0.03;

~stable = 0.dup(nScores);
~active = 0.dup(nScores);
~impulse = 0.0;
~batchProgress = 0.0;

OSCdef(\digest, { |msg|
	nScores.do { |i| ~active[i] = msg[i + 1].asFloat };
	~impulse = msg[nScores + 1].asFloat;
	("[86BB] Digest: impulse=" ++ ~impulse.round(0.001)
		++ " health_active=" ++ ~active[0].round(0.001)).postln;
}, '/86bb/digest');

OSCdef(\stable, { |msg|
	nScores.do { |i| ~stable[i] = msg[i + 1].asFloat };
	("[86BB] Stable: health=" ++ ~stable[0].round(0.001)).postln;
}, '/86bb/stable');

OSCdef(\batchProgress, { |msg|
	~batchProgress = msg[1].asFloat;
}, '/86bb/batch-progress');

~decayRoutine.stop;
~decayRoutine = Routine({
	inf.do {
		nScores.do { |i|
			~active[i] = ~active[i] + ((~stable[i] - ~active[i]) * decayRate);
		};
		// TODO: map ~active to synth/LED parameters here
		(1/30).wait;
	};
}).play(AppClock);

"[86BB] OSC responders registered (digest, stable, batch-progress, decay @30fps).".postln;
)
