(
~nBands = ~nBands ? 16;

SynthDef(\spectralPad, {
	arg out = 0, gate = 1, bufnum = 0,
	rate = 0, rateMin = -12, rateMax = 24,
	sourceFlux = 0.15, sourceFluxRate = 0.1,

	freqLo = 50, freqHi = 9000,
	rq = 1.0, rqMin = 0.01, rqMax = 1.0,
	bandAmRate = 0.075, bandAmRateMin = 0.01, bandAmRateMax = 0.3,
	filterFlux = 0.15, filterFluxRate = 0.1,

	scramble = 0.75, scrambleMin = 0.0, scrambleMax = 1.0,
	freezeThresh = 0.3, freezeThreshMin = 0.0, freezeThreshMax = 1.0,
	spectralFlux = 0.15, spectralFluxRate = 0.1,

	grainRate = 1.0, grainRateMin = 0.005, grainRateMax = 11,
	grainDur = 0.005, grainDurMin = 0.001, grainDurMax = 0.05,
	grainFlux = 0.15, grainFluxRate = 0.1,

	padAmRate = 5.0, padAmRateMin = 0.5, padAmRateMax = 53,
	padMaskRate = 0.025, padMaskRateMin = 0.01, padMaskRateMax = 0.1,
	padFlux = 0.15, padFluxRate = 0.1,

	dryWet = 0.75, dryWetMin = -1, dryWetMax = 1,
	grainPadMix = 0.75, grainPadMixMin = -1, grainPadMixMax = 1,
	mixFlux = 0.15, mixFluxRate = 0.1,

	gain = 0, lagTime = 2;

	var env, lagTimeL;
	var rateL, rateMinL, rateMaxL, sourceFluxL, sourceFluxRateL;
	var freqLoL, freqHiL;
	var rqL, rqMinL, rqMaxL, bandAmRateL, bandAmRateMinL, bandAmRateMaxL;
	var filterFluxL, filterFluxRateL;
	var scrambleL, scrambleMinL, scrambleMaxL;
	var freezeThreshL, freezeThreshMinL, freezeThreshMaxL;
	var spectralFluxL, spectralFluxRateL;
	var grainRateL, grainRateMinL, grainRateMaxL;
	var grainDurL, grainDurMinL, grainDurMaxL;
	var grainFluxL, grainFluxRateL;
	var padAmRateL, padAmRateMinL, padAmRateMaxL;
	var padMaskRateL, padMaskRateMinL, padMaskRateMaxL;
	var padFluxL, padFluxRateL;
	var dryWetL, dryWetMinL, dryWetMaxL;
	var grainPadMixL, grainPadMixMinL, grainPadMixMaxL;
	var mixFluxL, mixFluxRateL;
	var gainL;
	var sfr, rateNoise, rateLo, rateHi, currentRate, src;
	var directSig, pad, padMono, grainSig, padBpfSig;
	var mfr, dwNoise, dwLo, dwHi, dwVal, gpNoise, gpLo, gpHi, gpVal;
	var spectralMix, output;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
	lagTimeL = Lag.kr(lagTime, 0.5);

	rateL = VarLag.kr(rate, lagTime, 0);
	rateMinL = VarLag.kr(rateMin, lagTime, 0);
	rateMaxL = VarLag.kr(rateMax, lagTime, 0);
	sourceFluxL = VarLag.kr(sourceFlux, lagTime, 0);
	sourceFluxRateL = Lag.kr(sourceFluxRate, lagTimeL);

	freqLoL = Lag.kr(freqLo, lagTimeL);
	freqHiL = Lag.kr(freqHi, lagTimeL);
	rqL = VarLag.kr(rq, lagTime, 0);
	rqMinL = VarLag.kr(rqMin, lagTime, 0);
	rqMaxL = VarLag.kr(rqMax, lagTime, 0);
	bandAmRateL = Lag.kr(bandAmRate, lagTimeL);
	bandAmRateMinL = Lag.kr(bandAmRateMin, lagTimeL);
	bandAmRateMaxL = Lag.kr(bandAmRateMax, lagTimeL);
	filterFluxL = VarLag.kr(filterFlux, lagTime, 0);
	filterFluxRateL = Lag.kr(filterFluxRate, lagTimeL);

	scrambleL = VarLag.kr(scramble, lagTime, 0);
	scrambleMinL = VarLag.kr(scrambleMin, lagTime, 0);
	scrambleMaxL = VarLag.kr(scrambleMax, lagTime, 0);
	freezeThreshL = VarLag.kr(freezeThresh, lagTime, 0);
	freezeThreshMinL = VarLag.kr(freezeThreshMin, lagTime, 0);
	freezeThreshMaxL = VarLag.kr(freezeThreshMax, lagTime, 0);
	spectralFluxL = VarLag.kr(spectralFlux, lagTime, 0);
	spectralFluxRateL = Lag.kr(spectralFluxRate, lagTimeL);

	grainRateL = Lag.kr(grainRate, lagTimeL);
	grainRateMinL = Lag.kr(grainRateMin, lagTimeL);
	grainRateMaxL = Lag.kr(grainRateMax, lagTimeL);
	grainDurL = Lag.kr(grainDur, lagTimeL);
	grainDurMinL = Lag.kr(grainDurMin, lagTimeL);
	grainDurMaxL = Lag.kr(grainDurMax, lagTimeL);
	grainFluxL = VarLag.kr(grainFlux, lagTime, 0);
	grainFluxRateL = Lag.kr(grainFluxRate, lagTimeL);

	padAmRateL = Lag.kr(padAmRate, lagTimeL);
	padAmRateMinL = Lag.kr(padAmRateMin, lagTimeL);
	padAmRateMaxL = Lag.kr(padAmRateMax, lagTimeL);
	padMaskRateL = Lag.kr(padMaskRate, lagTimeL);
	padMaskRateMinL = Lag.kr(padMaskRateMin, lagTimeL);
	padMaskRateMaxL = Lag.kr(padMaskRateMax, lagTimeL);
	padFluxL = VarLag.kr(padFlux, lagTime, 0);
	padFluxRateL = Lag.kr(padFluxRate, lagTimeL);

	dryWetL = VarLag.kr(dryWet, lagTime, 0);
	dryWetMinL = VarLag.kr(dryWetMin, lagTime, 0);
	dryWetMaxL = VarLag.kr(dryWetMax, lagTime, 0);
	grainPadMixL = VarLag.kr(grainPadMix, lagTime, 0);
	grainPadMixMinL = VarLag.kr(grainPadMixMin, lagTime, 0);
	grainPadMixMaxL = VarLag.kr(grainPadMixMax, lagTime, 0);
	mixFluxL = VarLag.kr(mixFlux, lagTime, 0);
	mixFluxRateL = Lag.kr(mixFluxRate, lagTimeL);

	gainL = VarLag.kr(gain, lagTime, 0);

	// ── SOURCE ─────────────────────────────────────────────
	sfr = sourceFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
	rateNoise = LFNoise1.kr(sfr).range(0, 1);
	rateLo = rateL - ((rateL - rateMinL) * sourceFluxL);
	rateHi = rateL + ((rateMaxL - rateL) * sourceFluxL);
	currentRate = rateNoise.linlin(0, 1, rateLo, rateHi).midiratio;
	src = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * currentRate, loop: 1).sum * 0.5;

	// ── DIRECT FILTER BANK ─────────────────────────────────
	directSig = Mix.arFill(~nBands, { |i|
		var ffr, rqNoise, rqLogC, rqLogLo, rqLogHi, bandRqVal;
		var arNoise, arLogC, arLogLo, arLogHi, bandArVal;
		var freq, snd;

		ffr = filterFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		freq = i.linexp(0, ~nBands - 1, freqLoL, freqHiL);

		rqNoise = LFNoise1.kr(ffr).range(0, 1);
		rqLogC = rqL.log;
		rqLogLo = rqLogC - ((rqLogC - rqMinL.log) * filterFluxL);
		rqLogHi = rqLogC + ((rqMaxL.log - rqLogC) * filterFluxL);
		bandRqVal = rqNoise.linlin(0, 1, rqLogLo, rqLogHi).exp;

		arNoise = LFNoise1.kr(ffr).range(0, 1);
		arLogC = bandAmRateL.log;
		arLogLo = arLogC - ((arLogC - bandAmRateMinL.log) * filterFluxL);
		arLogHi = arLogC + ((bandAmRateMaxL.log - arLogC) * filterFluxL);
		bandArVal = arNoise.linlin(0, 1, arLogLo, arLogHi).exp;

		snd = BPF.ar(src, freq, bandRqVal);
		snd = snd * SinOsc.ar(bandArVal, Rand(-pi, pi)).range(0.2, 1);
		Pan2.ar(snd, LFNoise1.kr(ExpRand(0.1, 0.3), 4).tanh);
	});

	// ── SPECTRAL PAD ───────────────────────────────────────
	pad = Mix.arFill(2, { |i|
		var spfr, chain, scNoise, scLo, scHi, scVal;
		var ftNoise, ftLo, ftHi, ftVal, snd;

		spfr = spectralFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		chain = FFT(LocalBuf(4096), src);

		scNoise = LFNoise1.kr(spfr).range(0, 1);
		scLo = scrambleL - ((scrambleL - scrambleMinL) * spectralFluxL);
		scHi = scrambleL + ((scrambleMaxL - scrambleL) * spectralFluxL);
		scVal = scNoise.linlin(0, 1, scLo, scHi);

		ftNoise = LFNoise1.kr(spfr).range(0, 1);
		ftLo = freezeThreshL - ((freezeThreshL - freezeThreshMinL) * spectralFluxL);
		ftHi = freezeThreshL + ((freezeThreshMaxL - freezeThreshL) * spectralFluxL);
		ftVal = ftNoise.linlin(0, 1, ftLo, ftHi);

		chain = PV_BinScramble(chain, scVal, scVal, Dust.kr(0.1));
		chain = PV_Freeze(chain, LFNoise0.kr(1.2).range(0, 1) > ftVal);

		snd = IFFT(chain);
		Pan2.ar(snd, [-1, 1][i]) * LFNoise1.kr(ExpRand(0.1, 0.12)).range(0.5, 1);
	});
	padMono = pad.sum * 0.5;

	// ── GRAIN LAYER ────────────────────────────────────────
	grainSig = Mix.arFill(~nBands, { |i|
		var gfr, freq, rqVal, mul, band;
		var grNoise, grLogC, grLogLo, grLogHi, bandGrainRate;
		var gdNoise, gdLogC, gdLogLo, gdLogHi, bandGrainDur;
		var trig, grain, amp;

		gfr = grainFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		freq = i.linexp(0, ~nBands - 1, freqLoL * 1.6, freqHiL);
		rqVal = LFNoise1.kr(ExpRand(0.01, 0.1)).range(0.01, 0.5);

		grNoise = LFNoise1.kr(gfr).range(0, 1);
		grLogC = grainRateL.log;
		grLogLo = grLogC - ((grLogC - grainRateMinL.log) * grainFluxL);
		grLogHi = grLogC + ((grainRateMaxL.log - grLogC) * grainFluxL);
		bandGrainRate = grNoise.linlin(0, 1, grLogLo, grLogHi).exp;

		gdNoise = LFNoise1.kr(gfr).range(0, 1);
		gdLogC = grainDurL.log;
		gdLogLo = gdLogC - ((gdLogC - grainDurMinL.log) * grainFluxL);
		gdLogHi = gdLogC + ((grainDurMaxL.log - gdLogC) * grainFluxL);
		bandGrainDur = gdNoise.linlin(0, 1, gdLogLo, gdLogHi).exp;

		mul = rqVal.linlin(0.01, 0.75, 12, 1);
		band = BPF.ar(padMono, freq, rqVal, mul);
		trig = Impulse.ar(bandGrainRate);
		grain = GrainIn.ar(1, trig, bandGrainDur, band);
		amp = i.linlin(0, ~nBands - 1, 6, -3).dbamp *
			bandGrainRate.linlin(0.005, 5, 3.dbamp, 0.dbamp);
		grain = grain * amp;
		Pan2.ar(grain, LFNoise1.kr(ExpRand(0.05, 0.2)));
	});

	// ── PAD BPF LAYER ──────────────────────────────────────
	padBpfSig = Mix.arFill(~nBands, { |i|
		var pfr, freq, freqMod, bpf;
		var arNoise, arLogC, arLogLo, arLogHi, bandAmR;
		var mrNoise, mrLogC, mrLogLo, mrLogHi, bandMaskR;
		var ampMask, am;

		pfr = padFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		freq = i.linexp(0, ~nBands - 1, freqLoL * 2.4, freqHiL * 0.61);

		arNoise = LFNoise1.kr(pfr).range(0, 1);
		arLogC = padAmRateL.log;
		arLogLo = arLogC - ((arLogC - padAmRateMinL.log) * padFluxL);
		arLogHi = arLogC + ((padAmRateMaxL.log - arLogC) * padFluxL);
		bandAmR = arNoise.linlin(0, 1, arLogLo, arLogHi).exp;

		mrNoise = LFNoise1.kr(pfr).range(0, 1);
		mrLogC = padMaskRateL.log;
		mrLogLo = mrLogC - ((mrLogC - padMaskRateMinL.log) * padFluxL);
		mrLogHi = mrLogC + ((padMaskRateMaxL.log - mrLogC) * padFluxL);
		bandMaskR = mrNoise.linlin(0, 1, mrLogLo, mrLogHi).exp;

		freqMod = freq * LFNoise1.kr(ExpRand(0.1, 0.21), 6).midiratio;
		bpf = BPF.ar(padMono, freqMod, 0.75);
		ampMask = LFNoise1.ar(SinOsc.kr(0.001).exprange(bandMaskR * 0.8, bandMaskR * 1.2)).range(0, 1);
		am = SinOsc.ar(LFNoise1.kr(0.01).exprange(bandAmR * 0.1, bandAmR)).range(0, 1);
		bpf = bpf * ampMask * am;
		Pan2.ar(bpf, LFNoise1.kr(ExpRand(0.1, 0.3), 4).tanh);
	});

	// ── MIX ────────────────────────────────────────────────
	mfr = mixFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);

	dwNoise = LFNoise1.kr(mfr).range(0, 1);
	dwLo = dryWetL - ((dryWetL - dryWetMinL) * mixFluxL);
	dwHi = dryWetL + ((dryWetMaxL - dryWetL) * mixFluxL);
	dwVal = dwNoise.linlin(0, 1, dwLo, dwHi);

	gpNoise = LFNoise1.kr(mfr).range(0, 1);
	gpLo = grainPadMixL - ((grainPadMixL - grainPadMixMinL) * mixFluxL);
	gpHi = grainPadMixL + ((grainPadMixMaxL - grainPadMixL) * mixFluxL);
	gpVal = gpNoise.linlin(0, 1, gpLo, gpHi);

	spectralMix = XFade2.ar(padBpfSig * (-4).dbamp, grainSig * 2.dbamp, gpVal);
	output = XFade2.ar(directSig, spectralMix, dwVal);

	output = output * gainL.dbamp * env;
	Out.ar(out, output);
}).add;

("SynthDef \\spectralPad built and added (" ++ ~nBands ++ " bands)").postln;
)
