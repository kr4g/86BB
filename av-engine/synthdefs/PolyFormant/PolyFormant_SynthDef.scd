(
~nVox = ~nVox ? 8;

SynthDef(\polyFormant, {
	arg out = 0, gate = 1, wtBufStart = 0,
	fund = 43, fundMin = 24, fundMax = 84,
	fundLFORate = 0, fundLFOShape = 0, fundLFOSmooth = 0.1,
	ratio = 1.0, ratioMin = 0.5, ratioMax = 2.0,
	pitchFlux = 0.15, pitchFluxRate = 0.1,

	trigRate = 5.0, trigRateMin = 0.1, trigRateMax = 51,
	envSustain = 8.0, envSustainMin = 0.125, envSustainMax = 64,
	envRange = 0.5, envRangeMin = 0, envRangeMax = 1,
	prob = 1.0, probMin = 0, probMax = 1,
	trigFlux = 0.2, trigFluxRate = 0.1,

	shift = 10, shiftMin = -15, shiftMax = 55,
	bw = 110, bwMin = 55, bwMax = 440,
	formantFlux = 0.15, formantFluxRate = 0.1,

	amRate = 0.5, amRateMin = 0.01, amRateMax = 5,
	amDepth = 0.7, amDepthMin = 0, amDepthMax = 1,
	amSmooth = 0.05, amSmoothMin = 0, amSmoothMax = 0.5,
	amShape = 0.0, amShapeMin = 0, amShapeMax = 1,
	amFlux = 0.15, amFluxRate = 0.1,

	sampleRate = 48000, sampleRateMin = 12000, sampleRateMax = 48000,
	bitDepth = 24, bitDepthMin = 12, bitDepthMax = 24,
	decimFlux = 0.0, decimFluxRate = 0.1,

	gain = 18, lagTime = 2;

	var env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
	var lagTimeL = Lag.kr(lagTime, 0.5);

	var fundL = VarLag.kr(fund, lagTime, 0);
	var fundMinL = VarLag.kr(fundMin, lagTime, 0);
	var fundMaxL = VarLag.kr(fundMax, lagTime, 0);
	var fundLFORateL = Lag.kr(fundLFORate, lagTimeL);
	var fundLFOShapeL = VarLag.kr(fundLFOShape, lagTime, 0);
	var fundLFOSmoothL = VarLag.kr(fundLFOSmooth, lagTime, 0);
	var ratioL = Lag.kr(ratio, lagTimeL);
	var ratioMinL = Lag.kr(ratioMin, lagTimeL);
	var ratioMaxL = Lag.kr(ratioMax, lagTimeL);
	var pitchFluxL = VarLag.kr(pitchFlux, lagTime, 0);
	var pitchFluxRateL = Lag.kr(pitchFluxRate, lagTimeL);

	var trigRateL = Lag.kr(trigRate, lagTimeL);
	var trigRateMinL = Lag.kr(trigRateMin, lagTimeL);
	var trigRateMaxL = Lag.kr(trigRateMax, lagTimeL);
	var envSustainL = Lag.kr(envSustain, lagTimeL);
	var envSustainMinL = Lag.kr(envSustainMin, lagTimeL);
	var envSustainMaxL = Lag.kr(envSustainMax, lagTimeL);
	var envRangeL = VarLag.kr(envRange, lagTime, 0);
	var envRangeMinL = VarLag.kr(envRangeMin, lagTime, 0);
	var envRangeMaxL = VarLag.kr(envRangeMax, lagTime, 0);
	var probL = VarLag.kr(prob, lagTime, 0);
	var probMinL = VarLag.kr(probMin, lagTime, 0);
	var probMaxL = VarLag.kr(probMax, lagTime, 0);
	var trigFluxL = VarLag.kr(trigFlux, lagTime, 0);
	var trigFluxRateL = Lag.kr(trigFluxRate, lagTimeL);

	var shiftL = VarLag.kr(shift, lagTime, 0);
	var shiftMinL = VarLag.kr(shiftMin, lagTime, 0);
	var shiftMaxL = VarLag.kr(shiftMax, lagTime, 0);
	var bwL = Lag.kr(bw, lagTimeL);
	var bwMinL = Lag.kr(bwMin, lagTimeL);
	var bwMaxL = Lag.kr(bwMax, lagTimeL);
	var formantFluxL = VarLag.kr(formantFlux, lagTime, 0);
	var formantFluxRateL = Lag.kr(formantFluxRate, lagTimeL);

	var amRateL = Lag.kr(amRate, lagTimeL);
	var amRateMinL = Lag.kr(amRateMin, lagTimeL);
	var amRateMaxL = Lag.kr(amRateMax, lagTimeL);
	var amDepthL = VarLag.kr(amDepth, lagTime, 0).clip(0, 1);
	var amDepthMinL = VarLag.kr(amDepthMin, lagTime, 0);
	var amDepthMaxL = VarLag.kr(amDepthMax, lagTime, 0);
	var amSmoothL = VarLag.kr(amSmooth, lagTime, 0);
	var amSmoothMinL = VarLag.kr(amSmoothMin, lagTime, 0);
	var amSmoothMaxL = VarLag.kr(amSmoothMax, lagTime, 0);
	var amShapeL = VarLag.kr(amShape, lagTime, 0);
	var amShapeMinL = VarLag.kr(amShapeMin, lagTime, 0);
	var amShapeMaxL = VarLag.kr(amShapeMax, lagTime, 0);
	var amFluxL = VarLag.kr(amFlux, lagTime, 0);
	var amFluxRateL = Lag.kr(amFluxRate, lagTimeL);

	var sampleRateL = Lag.kr(sampleRate, lagTimeL);
	var sampleRateMinL = Lag.kr(sampleRateMin, lagTimeL);
	var sampleRateMaxL = Lag.kr(sampleRateMax, lagTimeL);
	var bitDepthL = VarLag.kr(bitDepth, lagTime, 0);
	var bitDepthMinL = VarLag.kr(bitDepthMin, lagTime, 0);
	var bitDepthMaxL = VarLag.kr(bitDepthMax, lagTime, 0);
	var decimFluxL = VarLag.kr(decimFlux, lagTime, 0);
	var decimFluxRateL = Lag.kr(decimFluxRate, lagTimeL);

	var gainL = VarLag.kr(gain, lagTime, 0);

	var voxAmps = ~nVox.collect { |i|
		VarLag.kr(NamedControl.kr(("vox" ++ (i+1) ++ "amp").asSymbol, 1.0), lagTime, 0);
	};

	var fundLFO = VOsc.kr(wtBufStart + (fundLFOShapeL * 3), fundLFORateL, 0);
	var fundBase;
	var sig;

	fundLFO = Lag.kr(fundLFO, fundLFOSmoothL);
	fundBase = (fundL + (fundLFO * (fundMaxL - fundMinL) * 0.5)).clip(fundMinL, fundMaxL);

	sig = Mix.arFill(~nVox, { |i|
		var pfr = pitchFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		var fundNoise = LFNoise1.kr(pfr).range(0, 1);
		var fundLo = fundBase - ((fundBase - fundMinL) * pitchFluxL);
		var fundHi = fundBase + ((fundMaxL - fundBase) * pitchFluxL);
		var voiceFund = fundNoise.linlin(0, 1, fundLo, fundHi);
		var voiceFundHz = voiceFund.midicps;
		var ratioNoise = LFNoise1.kr(pfr).range(0, 1);
		var ratioLogC = ratioL.log;
		var ratioLogLo = ratioLogC - ((ratioLogC - ratioMinL.log) * pitchFluxL);
		var ratioLogHi = ratioLogC + ((ratioMaxL.log - ratioLogC) * pitchFluxL);
		var voiceRatio = ratioNoise.linlin(0, 1, ratioLogLo, ratioLogHi).exp;

		var tfr = trigFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		var trNoise = LFNoise1.kr(tfr).range(0, 1);
		var trLogC = trigRateL.log;
		var trLogLo = trLogC - ((trLogC - trigRateMinL.log) * trigFluxL);
		var trLogHi = trLogC + ((trigRateMaxL.log - trLogC) * trigFluxL);
		var voiceTrigRate = trNoise.linlin(0, 1, trLogLo, trLogHi).exp;
		var rawTrig = Impulse.ar(voiceTrigRate);
		var probNoise = LFNoise1.kr(tfr).range(0, 1);
		var probLo = probL - ((probL - probMinL) * trigFluxL);
		var probHi = probL + ((probMaxL - probL) * trigFluxL);
		var voiceProb = probNoise.linlin(0, 1, probLo, probHi);
		var trig = rawTrig * (TRand.ar(0, 1, rawTrig) < voiceProb);
		var susNoise = LFNoise1.kr(tfr).range(0, 1);
		var susLogC = envSustainL.log;
		var susLogLo = susLogC - ((susLogC - envSustainMinL.log) * trigFluxL);
		var susLogHi = susLogC + ((envSustainMaxL.log - susLogC) * trigFluxL);
		var voiceSustain = susNoise.linlin(0, 1, susLogLo, susLogHi).exp;
		var erNoise = LFNoise1.kr(tfr).range(0, 1);
		var erLo = envRangeL - ((envRangeL - envRangeMinL) * trigFluxL);
		var erHi = envRangeL + ((envRangeMaxL - envRangeL) * trigFluxL);
		var voiceEnvRange = erNoise.linlin(0, 1, erLo, erHi);
		var spreadFactor = voiceEnvRange.linexp(0, 1, 1, 8);
		var envMulLo = voiceSustain / spreadFactor;
		var envMulHi = voiceSustain * spreadFactor;
		var pulsrEnv = EnvGen.ar(
			Env.perc(0.01, min(1 / voiceTrigRate, 0.05) * TRand.ar(envMulLo, envMulHi, trig)),
			trig,
			doneAction: Done.none
		);

		var ffr = formantFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		var shNoise = LFNoise1.kr(ffr).range(0, 1);
		var shLo = shiftL - ((shiftL - shiftMinL) * formantFluxL);
		var shHi = shiftL + ((shiftMaxL - shiftL) * formantFluxL);
		var voiceShift = shNoise.linlin(0, 1, shLo, shHi);
		var freq = voiceFundHz * (i.nthPrime.nthPrime) * voiceRatio + voiceShift;
		var bwNoise = LFNoise1.kr(ffr).range(0, 1);
		var bwLogC = bwL.log;
		var bwLogLo = bwLogC - ((bwLogC - bwMinL.log) * formantFluxL);
		var bwLogHi = bwLogC + ((bwMaxL.log - bwLogC) * formantFluxL);
		var voiceBW = bwNoise.linlin(0, 1, bwLogLo, bwLogHi).exp;
		var snd = Formant.ar(voiceFundHz, freq, voiceBW, mul: (1 / freq).pow(0.75));

		var afr = amFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		var arNoise = LFNoise1.kr(afr).range(0, 1);
		var arLogC = amRateL.log;
		var arLogLo = arLogC - ((arLogC - amRateMinL.log) * amFluxL);
		var arLogHi = arLogC + ((amRateMaxL.log - arLogC) * amFluxL);
		var voiceAmRate = arNoise.linlin(0, 1, arLogLo, arLogHi).exp;
		var adNoise = LFNoise1.kr(afr).range(0, 1);
		var adLo = amDepthL - ((amDepthL - amDepthMinL) * amFluxL);
		var adHi = amDepthL + ((amDepthMaxL - amDepthL) * amFluxL);
		var voiceAmDepth = adNoise.linlin(0, 1, adLo, adHi);
		var asNoise = LFNoise1.kr(afr).range(0, 1);
		var asLo = amSmoothL - ((amSmoothL - amSmoothMinL) * amFluxL);
		var asHi = amSmoothL + ((amSmoothMaxL - amSmoothL) * amFluxL);
		var voiceAmSmooth = asNoise.linlin(0, 1, asLo, asHi);
		var ashNoise = LFNoise1.kr(afr).range(0, 1);
		var ashLo = amShapeL - ((amShapeL - amShapeMinL) * amFluxL);
		var ashHi = amShapeL + ((amShapeMaxL - amShapeL) * amFluxL);
		var voiceAmShape = ashNoise.linlin(0, 1, ashLo, ashHi);
		var am = VOsc.ar(wtBufStart + (voiceAmShape * 3), voiceAmRate, 3pi/2).range(0, 1);

		var dfr = decimFluxRateL * LFNoise1.kr(0.01).range(0.95, 1.05);
		var srNoise = LFNoise1.kr(dfr).range(0, 1);
		var srLogC = sampleRateL.log;
		var srLogLo = srLogC - ((srLogC - sampleRateMinL.log) * decimFluxL);
		var srLogHi = srLogC + ((sampleRateMaxL.log - srLogC) * decimFluxL);
		var voiceSR = srNoise.linlin(0, 1, srLogLo, srLogHi).exp;
		var bdNoise = LFNoise1.kr(dfr).range(0, 1);
		var bdLo = bitDepthL - ((bitDepthL - bitDepthMinL) * decimFluxL);
		var bdHi = bitDepthL + ((bitDepthMaxL - bitDepthL) * decimFluxL);
		var voiceBD = bdNoise.linlin(0, 1, bdLo, bdHi);

		am = Lag.ar(am, voiceAmSmooth);
		am = am.linlin(0, 1, 1 - voiceAmDepth, 1);

		snd = Decimator.ar(snd, voiceSR, voiceBD);
		snd = snd * am;
		snd = snd * pulsrEnv;
		snd = Pan2.ar(snd, TIRand.ar(0, 1, trig) * 2 - 1);
		snd = snd * TRand.ar(0, 1, trig);
		snd = snd * voxAmps[i];
		snd;
	}) * gainL.dbamp;

	sig = sig * env;
	Out.ar(out, sig);
}).add;

("SynthDef \\polyFormant built and added (" ++ ~nVox ++ " voices)").postln;
)
