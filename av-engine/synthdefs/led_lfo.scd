SynthDef(\ledLFO, {
	arg outBus = 0, freqOutBus = 0, wtBufStart = 0,
	freqR = 0.15, freqG = 0.15, freqB = 0.15,
	waveR = 0.0, waveG = 0.0, waveB = 0.0,
	noiseFreqR = 0.15, noiseFreqG = 0.15, noiseFreqB = 0.15,
	noiseR = 0.0, noiseG = 0.0, noiseB = 0.0,
	minR = 0.0, minG = 0.0, minB = 0.0,
	maxR = 1.0, maxG = 1.0, maxB = 1.0,
	amFreqR = 1.0, amFreqG = 1.0, amFreqB = 1.0,
	amWaveR = 0.0, amWaveG = 0.0, amWaveB = 0.0,
	amDepthR = 0.0, amDepthG = 0.0, amDepthB = 0.0,
	brightness = 1.0,
	lagTime = 2.0, mute = 0;

	var makeChannel = { |freq, wave, noiseFreq, noiseMix, lo, hi, amFreq, amWave, amDepth|
		var lFreq = Lag.kr(freq, lagTime);
		var lWave = Lag.kr(wave, lagTime);
		var lNoiseFreq = Lag.kr(noiseFreq, lagTime);
		var lNoise = Lag.kr(noiseMix, lagTime);
		var lMin = Lag.kr(lo, lagTime);
		var lMax = Lag.kr(hi, lagTime);
		var lAmFreq = Lag.kr(amFreq, lagTime);
		var lAmWave = Lag.kr(amWave, lagTime);
		var lAmDepth = Lag.kr(amDepth, lagTime);

		var clean = VOsc.kr(wtBufStart + (lWave * 3), lFreq);
		var noise = LFNoise1.kr(lNoiseFreq);
		var baseLFO = ((1 - lNoise) * clean) + (lNoise * noise);
		var mapped = baseLFO.linlin(-1, 1, lMin, lMax);

		var amOsc = VOsc.kr(wtBufStart + (lAmWave * 3), lAmFreq);
		var amUni = (amOsc + 1) * 0.5;
		var amGate = 1 - (lAmDepth * (1 - amUni));

		mapped * amGate;
	};

	var r = makeChannel.(freqR, waveR, noiseFreqR, noiseR, minR, maxR, amFreqR, amWaveR, amDepthR);
	var g = makeChannel.(freqG, waveG, noiseFreqG, noiseG, minG, maxG, amFreqG, amWaveG, amDepthG);
	var b = makeChannel.(freqB, waveB, noiseFreqB, noiseB, minB, maxB, amFreqB, amWaveB, amDepthB);
	var bright = Lag.kr(brightness, lagTime);
	var muteGate = 1 - Lag.kr(mute, 0.05);

	Out.kr(outBus, ([r, g, b] * bright * muteGate).clip(0.0, 1.0));
	Out.kr(freqOutBus, [Lag.kr(freqR, lagTime), Lag.kr(freqG, lagTime), Lag.kr(freqB, lagTime)]);
}).add;
