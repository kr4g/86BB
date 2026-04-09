// ═══════════════════════════════════════════════════════════════════
// DRIPS — sine chirps with frequency sweeps, probability gating, AM
// ═══════════════════════════════════════════════════════════════════

SynthDef(\drips, {
	arg out = 0, gate = 1, wtBufStart = 0,

	prob1 = 0.66, prob2 = 0.66,
	wtPos1 = 0.0, wtPos2 = 0.0,
	amRate1 = 0.1, amRate2 = 0.1,
	amMul1 = 0.75, amMul2 = 0.75,

	freqWtPos1 = 0.0, freqWtPos2 = 0.0,
	freqRate1 = 0.1, freqRate2 = 0.1,

	sweepLo = 20, sweepHi = 20000,
	hpFreq = 2500,

	gain = -24, lagTime = 2;

	var env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);

	var makeCh = { |prob, wt, amR, amM, fWt, fR|
		var lProb = VarLag.kr(prob, lagTime, 0);
		var lWt = Lag.kr(wt, lagTime);
		var lAmR = VarLag.kr(amR, lagTime, 0).max(0.001);
		var lAmM = Lag.kr(amM, lagTime);
		var lFWt = Lag.kr(fWt, lagTime);
		var lFR = VarLag.kr(fR, lagTime, 0).max(0.001);
		var lSweepLo = VarLag.kr(sweepLo, lagTime, 0).max(20);
		var lSweepHi = VarLag.kr(sweepHi, lagTime, 0).max(100);
		var lHpFreq = VarLag.kr(hpFreq, lagTime, 0).max(20);

		var am = VOsc.ar(wtBufStart + (lWt * 3), lAmR, 3pi/2).range(0, 1);
		var mul = am * lAmM * LFNoise1.kr(Rand(0.05, 0.07)).range(0.67, 1);

		var trigFreq = VOsc.ar(wtBufStart + (lFWt * 3), lFR, 3pi/2).exprange(0.1, 11);
		var trig = Impulse.ar(trigFreq);

		var dur = trigFreq.explin(0.1, 11, 0.05, 0.01);
		var peakEnv = EnvGen.ar(Env.perc(0.01, dur, curve: -8), trig, doneAction: 0);

		var phase = Sweep.ar(trig, 1 / dur).clip(0, 1);
		var freqEnv = phase.linexp(0, 1, lSweepLo, lSweepHi);

		var sig = SinOsc.ar(freqEnv, mul: 0.25) * peakEnv;
		sig = HPF.ar(sig, lHpFreq);
		sig = sig * mul * (TRand.ar(0, 1, trig) < lProb);
		sig;
	};

	var ch1 = makeCh.(prob1, wtPos1, amRate1, amMul1, freqWtPos1, freqRate1);
	var ch2 = makeCh.(prob2, wtPos2, amRate2, amMul2, freqWtPos2, freqRate2);

	var sig = [ch1, ch2] * Lag.kr(gain, lagTime).dbamp * env;
	Out.ar(out, sig);
}).add;

// ═══════════════════════════════════════════════════════════════════
// PURRS — LFPulse rumble through LPF, wavetable LFO on freq, AM
// ═══════════════════════════════════════════════════════════════════

SynthDef(\purrs, {
	arg out = 0, gate = 1, wtBufStart = 0,

	freqMin1 = 3, freqMin2 = 3,
	freqMax1 = 31, freqMax2 = 31,
	freqWtPos1 = 0.0, freqWtPos2 = 0.0,
	freqRate1 = 0.05, freqRate2 = 0.05,

	width1 = 0.5, width2 = 0.5,
	wtPos1 = 0.0, wtPos2 = 0.0,
	amRate1 = 0.1, amRate2 = 0.1,
	amMul1 = 0.75, amMul2 = 0.75,

	lpFreq1 = 120, lpFreq2 = 120,

	gain = 0, lagTime = 2;

	var env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);

	var makeCh = { |fMin, fMax, fWt, fR, width, wt, amR, amM, lpF|
		var lFMin = VarLag.kr(fMin, lagTime, 0).max(0.5);
		var lFMax = VarLag.kr(fMax, lagTime, 0).max(1);
		var lFWt = Lag.kr(fWt, lagTime);
		var lFR = VarLag.kr(fR, lagTime, 0).max(0.001);
		var lWidth = Lag.kr(width, lagTime).clip(0, 1);
		var lWt = Lag.kr(wt, lagTime);
		var lAmR = VarLag.kr(amR, lagTime, 0).max(0.001);
		var lAmM = Lag.kr(amM, lagTime);
		var lLpF = VarLag.kr(lpF, lagTime, 0).max(20);

		var freq = VOsc.kr(wtBufStart + (lFWt * 3), lFR, 3pi/2).exprange(lFMin, lFMax);

		var am = VOsc.ar(wtBufStart + (lWt * 3), lAmR, 3pi/2).range(0, 1);
		var mul = am * lAmM * LFNoise1.kr(Rand(0.05, 0.07)).range(0.67, 1);

		var sig = LFPulse.ar(freq, width: lWidth, mul: mul) * 0.5;
		sig = LPF.ar(sig, lLpF);
		sig;
	};

	var ch1 = makeCh.(freqMin1, freqMax1, freqWtPos1, freqRate1, width1, wtPos1, amRate1, amMul1, lpFreq1);
	var ch2 = makeCh.(freqMin2, freqMax2, freqWtPos2, freqRate2, width2, wtPos2, amRate2, amMul2, lpFreq2);

	var sig = [ch1, ch2] * Lag.kr(gain, lagTime).dbamp * env;
	Out.ar(out, sig);
}).add;

// ═══════════════════════════════════════════════════════════════════
// BURPS — formant chirps with comb reverb + pitch shift
// ═══════════════════════════════════════════════════════════════════

SynthDef(\burps, {
	arg out = 0, gate = 1,

	trigRate1 = 0.3, trigRate2 = 0.3,
	fund = 6,
	sweepHiMin = 16, sweepHiMax = 128,
	formantBW = 55,
	combMix = -3,

	gain = 0, lagTime = 2;

	var env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
	var lFund = VarLag.kr(fund, lagTime, 0).max(1);
	var lBW = VarLag.kr(formantBW, lagTime, 0).max(10);
	var lSweepHiMin = VarLag.kr(sweepHiMin, lagTime, 0);
	var lSweepHiMax = VarLag.kr(sweepHiMax, lagTime, 0);

	var makeCh = { |tRate|
		var lTrigRate = VarLag.kr(tRate, lagTime, 0).max(0.01);
		var combTime = Rand(0.11, 0.14);
		var pitchRatio = Rand(0.67, 0.75);
		var trig = Dust.kr(lTrigRate);
		var dur = lTrigRate.explin(0.1, 1.2, 0.5, 0.1);
		var phase = Sweep.ar(trig, 1 / dur).clip(0, 1);
		var freqEnv = phase.linexp(0, 1, lFund * 4, lFund * TExpRand.ar(lSweepHiMin, lSweepHiMax, trig));
		var sig = Formant.ar(lFund, freqEnv, lBW, mul: -5.dbamp);
		var envPulse = EnvGen.ar(Env.perc(0.01, dur), trig, doneAction: Done.none);
		var comb;

		sig = sig * envPulse * LFNoise1.ar(Rand(0.08, 0.12)).range(0, 1);

		comb = CombL.ar(sig, 0.2, combTime, 2);
		comb = PitchShift.ar(comb, 0.2, pitchRatio, 0.01, 0.001);
		comb = comb * Lag.kr(combMix, lagTime).dbamp;

		sig + comb;
	};

	var ch1 = makeCh.(trigRate1);
	var ch2 = makeCh.(trigRate2);

	var sig = [ch1, ch2] * Lag.kr(gain, lagTime).dbamp * env;
	Out.ar(out, sig);
}).add;

("SynthDefs \\drips, \\purrs, \\burps built and added.").postln;
