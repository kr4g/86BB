(
{
	var fund = 55 * LFNoise1.kr([0.08, 0.05, 0.03]).midiratio;
	var trig = Dust.kr(1.3);
	var formFreq = fund * LFNoise0.kr([0.3, 0.5, 0.8]).exprange(2.0, 16);
	var bw = LFNoise1.kr(1.1).exprange(55, 110);
	var sig = Formant.ar(fund, formFreq, bw);
	var amp = LFNoise1.kr([0.13, 0.21, 0.34] * 3).range(0, 1);
	sig = Splay.ar(sig);
	sig = sig * -24.dbamp * amp;
}.play;
)


(
{
	var n_vox = 4;
	var sig = Mix.arFill(n_vox, { |i|
		var fund = 55 * LFNoise1.kr(ExpRand(0.003, 0.13)).midiratio;
		var formFreq = (2 * fund) * (i.nthPrime) * LFNoise1.kr(ExpRand(0.003, 0.13)).midiratio;
		var bw = LFNoise1.kr(ExpRand(0.9, 2.1)).exprange(55, 110);
		var snd = Formant.ar(fund, formFreq, bw, (1/formFreq).pow(0.5));
		var amp = LFNoise1.kr(ExpRand(0.13, 0.34) * 3).range(0, 1);
		snd = snd * amp;
	});

	var sweepMul = SinOsc.kr(0.06, 3pi/2).exprange(0.5, 16);

	var bpf = Mix.arFill(n_vox * 4, { |i|
		var filtFreq = LFNoise1.ar(ExpRand(0.08, 0.13) * sweepMul).exprange(55, 7040*2);
		var snd = BPF.ar(sig, filtFreq, rq: LFNoise1.kr(ExpRand(0.1, 0.25)).range(0.001, 0.1));
		snd;
	});

	var trigRate = LFNoise1.ar(0.04).exprange(0.25, 21);
	var trig = Impulse.kr(trigRate);
	var curve = trigRate.explin(0.25, 21, -4, -8);
	var pulsrEnv = EnvGen.ar(
		Env.perc(0.01, (1 / trigRate).pow(1.1), curve: curve),
		trig,
		doneAction: Done.none
	);

	// sig = LPF.ar(sig, 900);

	// sig = XFade2.ar(sig, bpf, LFNoise1.kr(0.2));

	sig = bpf;

	sig = sig * pulsrEnv;

	sig;
}.play;
)

(
fork{
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	~testWT = Buffer.allocConsecutive(5, s, sigSize * 2);
	s.sync;

	sigs[0] = Signal.newClear(sigSize);
	sigs[0].waveFill({ |x| sin(x) }, 0, 2pi);

	sigs[1] = Signal.newClear(sigSize);
	sigs[1].waveFill({ |x|
		var phase = x / 2pi;
		if(phase < 0.5, { phase * 4 - 1 }, { 3 - (phase * 4) });
	}, 0, 2pi);

	sigs[2] = Signal.newClear(sigSize);
	sigs[2].waveFill({ |x| (x / 2pi) * 2 - 1 }, 0, 2pi);

	sigs[3] = Signal.newClear(sigSize);
	sigs[3].waveFill({ |x| if(x < pi, { 1.0 }, { -1.0 }) }, 0, 2pi);

	sqSig = sigs[3].asWavetable;
	4.do { |i| ~testWT[i].loadCollection(sigs[i].asWavetable) };
	~testWT[4].loadCollection(sqSig);
	s.sync;

	~testWTStart = ~testWT[0].bufnum;
	"Wavetable buffers ready (bufs % - %, guard at %).".format(
		~testWTStart, ~testWTStart + 3, ~testWTStart + 4).postln;
});
};
)

({
	var ratio = LFNoise1.kr(0.02).range(1, 6);
	var fund = 110 * LFNoise0.kr(0.2 * LFNoise1.kr(0.1).exprange(1, 35), mul: ratio).midiratio;
	var sig = Mix.arFill(16, { |i|
		var form = (fund * 1) * (i + 1) * LFNoise1.kr(ExpRand(0.05, 0.1), mul: 2).midiratio;
		var bw = LFNoise1.kr(0.2 * i.nthPrime).exprange(55, 220);
		var snd = Formant.ar(fund * 0.5, form, bw, (1/form).pow(0.5));
		snd = snd * SinOsc.ar(ExpRand(0.1, 0.3) * LFNoise1.kr(ExpRand(0.05, 0.1)).exprange(0.5, 7)).range(0, 1);
		// snd = snd * SinOsc.ar(ExpRand(0.06, 0.1)).range(0, 1);
		snd;
	});

	var lpf = LPF.ar(sig, LFNoise1.kr(0.11).exprange(250, 1500), mul: -12.dbamp);
	var bpf = BPF.ar(sig, LFSaw.kr(0.12 * 10.collect{ LFNoise1.kr(ExpRand(0.1, 0.3)).exprange(0.1, 5) }, 1).exprange(250, 9500), 0.05, mul: 6.dbamp);

	var trigRate = LFNoise1.kr(0.1).exprange(0.1, 13);

	sig = XFade2.ar(lpf, bpf, LFNoise1.kr(0.09));
	// sig = XFade2.ar(lpf, bpf, -1);

	sig = Splay.ar(sig) * 0.75;

	sig = sig * EnvGen.ar(
		Env.perc(0.01, trigRate.explin(0.1, 13, 8, 1/13), curve: -8),
		Dust.ar(trigRate),
		doneAction: Done.none
	);

	sig;

}.play;
)


// POLY-FORMANT

({
	var fund = 55 * LFNoise1.kr(0.005, 2).midiratio * LFNoise1.ar(0.05, 0.33).midiratio;
	var ratio = 1;//LFNoise1.kr(0.1).exprange(0.5, 2);
	var sig = Mix.arFill(12, { |i|

		var trigRate = LFNoise1.kr(ExpRand(0.01, 0.5)).exprange(0.1, 51);
		var trig = Impulse.ar(trigRate);

		var offset = LFNoise1.kr(ExpRand(0.05, 0.1)).range(-15, 55);
		var freq = fund * (i.nthPrime.nthPrime) * ratio + offset;

		var morph = SinOsc.kr(ExpRand(0.01, 0.5), 3pi/2).range(0, 1);
		// var snd = VOsc.ar(~testWTStart + (morph * 3), freq, mul: (1 / freq).pow(0.75));
		var snd = Formant.ar(fund, freq, morph.linexp(0, 1, 55, 440), mul: (1 / freq).pow(0.75));

		var amRate = SinOsc.ar(ExpRand(0.01, 0.05)).exprange(0.01, 5);
		// var am = SinOsc.ar(amRate, 3pi/2).range(0, 1);
		var am = VOsc.ar(~wtBufStart + (morph * 3), amRate, 3pi/2).range(0, 1);

		var envMulMin = LFNoise1.kr(ExpRand(0.01, 0.1)).range(0.125, 8);
		var envMulMax = LFNoise1.kr(ExpRand(0.01, 0.1)).range(8, 64);
		var pulsrEnv = EnvGen.ar(
			Env.perc(0.01, min(1 / trigRate, 0.05) * TRand.ar(envMulMin, envMulMax, trig)),
			trig,
			doneAction: Done.none
		);

		var bitRate = LFNoise1.kr(ExpRand(0.01, 0.125)).range(0, 1);
		var bitDepth = 24;//LFNoise1.kr(ExpRand(0.01, 0.125)).range(0, 1);
		snd = Decimator.ar(snd, bitRate.linexp(0, 1, 12000, 48000), bitDepth.linexp(0, 1, 12, 24));

		snd = snd * am;
		snd = snd * pulsrEnv;

		snd = Pan2.ar(snd, TRand.ar(-1, 1, trig));

		snd = snd * TRand.ar(0, 1, trig);

		snd;
	}) * 18.dbamp;

	sig;

}.play;
)

// SPECTRAL v2 — Freeze + MagSmear (pad approach)
(
var b = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "../samples/gut_recording.wav");

{
	var n_bands = 24;
	var rateRatio = LFNoise1.kr(0.1).range(-12, 24).midiratio;
	var src = PlayBuf.ar(2, b, 1 * rateRatio, loop:1).sum * 0.5;
	var ampEnv = Amplitude.ar(src, 0.01, 0.1);

	var sig = Mix.arFill(n_bands, { |i|
		var freq = i.linexp(0, n_bands - 1, 50, 9000);
		var rq = 1;//i.linlin(0, n_bands - 1, 0.1, 0.05);
		var mul = 1;//i.linexp(0, n_bands - 1, 1, 4);
		var snd = BPF.ar(src, freq, rq, mul);
		snd = snd * SinOsc.ar(ExpRand(0.05, 0.1), Rand(-pi, pi)).range(0.2, 1);
		snd = Pan2.ar(snd, LFNoise1.kr(ExpRand(0.1, 0.3), 4).tanh);
		snd;
	});

	var pad = Mix.arFill(2, { |i|
		var chain = FFT(LocalBuf(2048*1), src);
		var snd;

		chain = PV_BinScramble(chain,
			LFNoise1.kr(1.1).range(0.5, 1),
			LFNoise1.kr(1.9).range(0.5, 1),
			Dust.kr(0.1)
		);

		chain = PV_Freeze(chain, LFNoise0.kr(0.2).range(0, 1) > 0.3);

		snd = IFFT(chain);
		Pan2.ar(snd, [-1, 1][i]) * LFNoise1.kr(ExpRand(0.12, 0.11)).range(0.5, 1);
	});

	var padMono = pad.sum * 0.5;

	var grains = Mix.arFill(n_bands, { |i|
		var freq = i.linexp(0, n_bands - 1, 80, 9000);
		var rq = LFNoise1.kr(ExpRand(0.01, 0.1)).range(0.5, 0.01);
		var mul = rq.linlin(0.01, 0.75, 12, 1);
		var band = BPF.ar(padMono, freq, rq, mul);
		var trigRate = LFNoise1.kr(ExpRand(0.01, 0.08)).exprange(0.005, 11);
		var trig = Impulse.ar(trigRate);
		var dur = LFNoise1.kr(ExpRand(0.01, 0.08)).exprange(0.001, 0.01);
		var grain = GrainIn.ar(1, trig, dur, band);
		var amp = i.linlin(0, n_bands - 1, 6, -3).dbamp * trigRate.linlin(0.005, 5, 3.dbamp, 0.dbamp);
		var ampMask = 1;//LFNoise1.ar(SinOsc.kr(0.01, Rand(-pi, pi)).exprange(0.1, 0.5)).range(0.75, 1);
		grain = grain * amp * ampMask;
		Pan2.ar(grain, LFNoise1.kr(ExpRand(0.05, 0.2)));
	});

	var padBpf = Mix.arFill(n_bands, { |i|
		// var freq = SinOsc.kr(ExpRand(0.08, 0.13)).exprange(300, 4500) * LFNoise1.kr(ExpRand(0.1, 0.21), 6).midiratio;
		var freq = i.linexp(0, n_bands - 1, 120, 5500) * LFNoise1.kr(ExpRand(0.1, 0.21), 6).midiratio;
		var bpf = BPF.ar(padMono, freq, 0.75);
		var ampMask = LFNoise1.ar(SinOsc.kr(0.001).exprange(0.02, 0.03)).range(0, 1) * LFNoise1.ar(ExpRand(0.2, 0.3)).range(0.5, 1);
		// var am = SinOsc.ar(LFNoise1.kr(0.01).exprange(0.5, 53)).range(0, 1);
		bpf = bpf * ampMask;

		bpf = FreqShift.ar(bpf, LFNoise0.kr(SinOsc.kr(ExpRand(0.01, 0.05)).exprange(0.01, 0.3)).range(-150, 150));

		bpf = Pan2.ar(bpf, LFNoise1.kr(ExpRand(0.1, 0.3), 4).tanh);
		bpf;
	});

	var mix = XFade2.ar(padBpf * -6.dbamp, grains * 2.dbamp, LFNoise1.kr(0.05).range(0, 1));

	var out = XFade2.ar(sig, mix, LFNoise1.kr(0.03).range(0, 1));

	out;
	// padBpf * -4.dbamp;

}.play(outbus: 2);
)

// --------------------------------------------
// VERSION 2
// --------------------------------------------

// DRIPS
(
{
	var prob = LFNoise1.kr([0.05, 0.07]).range(0.33, 1);
	var morph = SinOsc.kr([0.02, 0.03], 3pi/2).range(0, 1);
	var amRate = SinOsc.ar([0.05, 0.08]).exprange(0.013, 0.5);
	var am = VOsc.ar(~wtBufStart + (morph * 3), amRate, 3pi/2).range(0, 1);
	var mul = am * LFNoise1.kr([0.05, 0.07]).range(0.5, 1);

	var freqMorph = SinOsc.kr([0.05, 0.07], 3pi/2).range(0, 1);
	var freqRate = LFNoise1.kr([0.05, 0.08]).exprange(0.01, 0.7);
	var freq = VOsc.ar(~wtBufStart + (freqMorph * 3), freqRate, 3pi/2).exprange(0.1, 11);

	var trig = Impulse.ar(freq);

	var dur = freq.explin(0.1, 11, 0.05, 0.01);

	var env = EnvGen.ar(
		Env.perc(0.01, dur, curve: -8),
		trig,
		doneAction: Done.none
	);

	var phase = Sweep.ar(trig, 1/dur).clip(0, 1);
	var freqEnv = phase.linexp(0, 1, 20, 20000);
	// var freqEnv = LFNoise1.ar(550).exprange(20, 20000);

	var sig = SinOsc.ar(freqEnv, mul:0.25) * env;

	// var crush = FreqShift.ar(Decimator.ar(sig.reverse, TExpRand.ar(8000, 48000, trig), TRand.ar(8, 24, trig)), freq: TRand.ar(-1550, 1550, trig));

	// var hpf = HPF.ar(sig + (crush * -16.dbamp), 1500);
	var hpf = HPF.ar(sig, 2500);
	// var lpf = LPF.ar(sig, 250);
	// sig = lpf + hpf;
	sig = hpf;

	// sig = PitchShift.ar(sig, 0.1, TExpRand.ar(0.25, 1, trig), 0.01, 0.001);

	sig = sig * mul * (TRand.ar(0, 1, trig) < prob);

	sig * -24.dbamp;

}.play;
)

// PURRS
({
	var morph = SinOsc.kr([0.02, 0.03], 3pi/2).range(0, 1);
	var amRate = SinOsc.ar([0.05, 0.08]).exprange(0.013, 0.5);
	var am = VOsc.ar(~wtBufStart + (morph * 3), amRate, 3pi/2).range(0, 1);

	var freq = LFNoise1.kr([0.05, 0.08]).exprange(3, 31);
	var width = LFNoise1.kr([0.11, 0.13]).range(0, 1);
	var mul = am * LFNoise1.kr([0.05, 0.07]).range(0.5, 1);

	var sig = LFPulse.ar(freq, width:width, mul:mul) * 0.5;

	var lpFreq = LFNoise1.kr([0.23, 0.31]).exprange(80, 250);
	sig = LPF.ar(sig, lpFreq);

	sig;

}.play;
)

// BURPS
(
{
	var minTrigRate = 0.1;
	var maxTrigRate = 1.2;
	var trigRate = LFNoise1.kr(LFNoise1.kr([0.005, 0.008]).exprange(0.01, 0.1)).exprange(minTrigRate, maxTrigRate);
	var trig = Dust.kr(trigRate);

	var dur = trigRate.explin(minTrigRate, maxTrigRate, 0.5, 0.1);

	var fund = 6;
	var phase = Sweep.ar(trig, 1/dur).clip(0, 1);
	var freqEnv = phase.linexp(0, 1, fund*4, fund*TExpRand.ar(16, 128, trig));

	var sig = Formant.ar(fund, freqEnv, 55, mul: -5.dbamp);

	var envPulse = EnvGen.ar(
		Env.perc(0.01, dur),
		trig,
		doneAction: Done.none
	);

	var comb;

	sig = sig * envPulse * LFNoise1.ar([0.09, 0.11]).range(0, 1);

	comb = Mix.arFill(2, { |i|
		var snd = CombL.ar(sig, 0.2, Rand(0.11, 0.14), 2);
		snd = PitchShift.ar(snd, 0.2, Rand(0.67, 0.75), 0.01, 0.001);
		snd = Pan2.ar(snd, [-1, 1][i]);
		snd * -3.dbamp;
	});

	sig = sig + comb;

	sig;

}.play;
)