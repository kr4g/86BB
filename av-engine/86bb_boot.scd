ServerOptions.devices;

(
~decayRoutine.stop;
~modelLoaded = false;
Server.killAll;
Buffer.freeAll;
s = Server.local;

~numLEDs = 5;
~nBioScores = 8;
~nChans = 4;
~sr = 48000;

s.options.outDevice_(
	"MacBook Pro Speakers"
	// "UMC404HD 192k"
);
s.options.numOutputBusChannels_(~nChans);
s.options.numInputBusChannels_(0);
s.options.sampleRate_(~sr);
s.options.memSize_(2.pow(20));
s.newBusAllocators;

s.waitForBoot({
	var basePath = thisProcess.nowExecutingPath.dirname;
	var modelsPath = basePath +/+ "models";
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	var allParams, channelLabels, nLedOutputDims, nTransducerDims, nOutputDims;

	"[86BB] Server booted.".postln;

	// ========== WAVETABLE BUFFERS ==========
	~wtBufs = Buffer.allocConsecutive(5, s, sigSize * 2);
	s.sync;
	sigs[0] = Signal.newClear(sigSize);
	sigs[0].waveFill({ |x| sin(x) }, 0, 2pi);
	sigs[1] = Signal.newClear(sigSize);
	sigs[1].waveFill({ |x| var phase = x / 2pi; if(phase < 0.5, { phase * 4 - 1 }, { 3 - (phase * 4) }) }, 0, 2pi);
	sigs[2] = Signal.newClear(sigSize);
	sigs[2].waveFill({ |x| (x / 2pi) * 2 - 1 }, 0, 2pi);
	sigs[3] = Signal.newClear(sigSize);
	sigs[3].waveFill({ |x| if(x < pi, { 1.0 }, { -1.0 }) }, 0, 2pi);
	sqSig = sigs[3].asWavetable;
	4.do { |i| ~wtBufs[i].loadCollection(sigs[i].asWavetable) };
	~wtBufs[4].loadCollection(sqSig);
	s.sync;
	~wtBufStart = ~wtBufs[0].bufnum;
	("[86BB] Wavetable buffers ready.").postln;

	// ========== SYNTHDEFS ==========
	(basePath +/+ "synthdefs/leds.scd").load;
	(basePath +/+ "synthdefs/transducers.scd").load;
	s.sync;
	"[86BB] SynthDefs loaded.".postln;

	// ========== LED BUSES / SYNTHS ==========
	~espAddr = NetAddr("192.168.8.175", 9000);
	~ledBus = Bus.control(s, ~numLEDs * 3);
	~freqBus = Bus.control(s, ~numLEDs * 3);
	~lfoGroup = Group.new;
	~collectorGroup = Group.after(~lfoGroup);
	~lfo = ~numLEDs.collect({ |i|
		Synth(\ledLFO, [\outBus, ~ledBus.index + (i * 3), \freqOutBus, ~freqBus.index + (i * 3), \wtBufStart, ~wtBufStart], ~lfoGroup);
	});
	~collector = Synth(\ledCollector, [\ledBusIndex, ~ledBus.index, \freqBusIndex, ~freqBus.index], ~collectorGroup);

	~ledPreview = Array.newClear(~numLEDs);
	defer {
		~ledPreviewWin = Window("LED Preview", Rect(50, 50, ~numLEDs * 120, 120)).front;
		~ledPreviewWin.view.layout = HLayout(*~numLEDs.collect({ |i|
			var v = View().background_(Color.gray(0.1));
			~ledPreview[i] = v;
			v;
		})).margins_(4).spacing_(4);
	};

	OSCdef(\ledForward, { |msg|
		var values = msg[3..];
		try { ~espAddr.sendMsg("/all", *values) };
		defer {
			~numLEDs.do { |i|
				var ri = i * 3;
				if(~ledPreview[i].notNil and: { ~ledPreview[i].isClosed.not }, {
					~ledPreview[i].background = Color(values[ri] ? 0, values[ri+1] ? 0, values[ri+2] ? 0);
				});
			};
		};
	}, '/leds');
	s.sync;
	"[86BB] 5 LED synths ready (preview window open).".postln;

	// ========== TRANSDUCER SYNTHS ==========
	~drips = Synth(\drips, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~purrs = Synth(\purrs, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~burps = Synth(\burps, [\out, 0, \gain, -96]);
	s.sync;
	"[86BB] Transducer synths ready (drips, purrs, burps).".postln;

	// ========== PARAM PACKING (must match trainer) ==========
	allParams = [\freq, \wave, \noiseFreq, \noise, \min, \max, \amFreq, \amWave, \amDepth];
	channelLabels = ["R", "G", "B"];
	nLedOutputDims = (~numLEDs * ((allParams.size * 3) + 1)) + 4;

	~dripsFlat = [\prob1, \prob2, \wtPos1, \wtPos2, \amRate1, \amRate2, \amMul1, \amMul2,
		\freqWtPos1, \freqWtPos2, \freqRate1, \freqRate2, \sweepLo, \sweepHi, \hpFreq, \gain];
	~purrsFlat = [\freqMin1, \freqMin2, \freqMax1, \freqMax2, \freqWtPos1, \freqWtPos2,
		\freqRate1, \freqRate2, \width1, \width2, \wtPos1, \wtPos2,
		\amRate1, \amRate2, \amMul1, \amMul2, \lpFreq1, \lpFreq2, \gain];
	~burpsFlat = [\trigRate1, \trigRate2, \fund, \sweepHiMin, \sweepHiMax, \formantBW, \combMix, \gain];
	nTransducerDims = ~dripsFlat.size + ~purrsFlat.size + ~burpsFlat.size;
	nOutputDims = nLedOutputDims + nTransducerDims;

	~applyPrediction = { |arr|
		var idx = 0;
		~numLEDs.do { |led|
			allParams.do { |group|
				3.do { |ci|
					var key = (group ++ channelLabels[ci]).asSymbol;
					~lfo[led].set(key, arr[idx]);
					idx = idx + 1;
				};
			};
			~lfo[led].set(\brightness, arr[idx]);
			idx = idx + 1;
		};
		~collector.set(\gamma, arr[idx]);
		~collector.set(\rateMultiplier, arr[idx + 1]);
		~collector.set(\minRate, arr[idx + 2]);
		~collector.set(\maxRate, arr[idx + 3]);
		idx = idx + 4;

		[[\drips, ~dripsFlat, ~drips], [\purrs, ~purrsFlat, ~purrs], [\burps, ~burpsFlat, ~burps]].do { |triple|
			triple[1].do { |param|
				triple[2].set(param, arr[idx]);
				idx = idx + 1;
			};
		};
	};

	// ========== FLUCOMA MODEL ==========
	~modelLoaded = false;
	~mlp = FluidMLPRegressor(s);
	~inputNorm = FluidNormalize(s);
	~outputNorm = FluidNormalize(s);
	~inputBuf = Buffer.alloc(s, ~nBioScores);
	~outputBuf = Buffer.alloc(s, nOutputDims);
	~inputBufNormed = Buffer.alloc(s, ~nBioScores);
	~outputBufNormed = Buffer.alloc(s, nOutputDims);
	s.sync;

	if(File.exists(modelsPath +/+ "av_mlp.json"), {
		"[86BB] Loading FluCoMa AV model (LED + transducers)...".postln;
		~mlp.read(modelsPath +/+ "av_mlp.json", {
			~inputNorm.read(modelsPath +/+ "av_input_norm.json", {
				~outputNorm.read(modelsPath +/+ "av_output_norm.json", {
					~modelLoaded = true;
					"[86BB] FluCoMa AV model ready.".postln;
				});
			});
		});
	}, {
		if(File.exists(modelsPath +/+ "led_mlp.json"), {
			"[86BB] No AV model found. Loading legacy LED-only model...".postln;
			~mlp.read(modelsPath +/+ "led_mlp.json", {
				~inputNorm.read(modelsPath +/+ "led_input_norm.json", {
					~outputNorm.read(modelsPath +/+ "led_output_norm.json", {
						~modelLoaded = true;
						"[86BB] Legacy LED-only model loaded (transducers will not be predicted).".postln;
					});
				});
			});
		}, {
			"[86BB] No model found — running without prediction.".postln;
		});
	});

	~predicting = false;
	~predictFromBioScores = { |bioScores|
		if(~modelLoaded == true and: { ~predicting == false }, {
			~predicting = true;
			fork {
				~inputBuf.loadCollection(bioScores);
				s.sync;
				~inputNorm.transformPoint(~inputBuf, ~inputBufNormed, {
					~mlp.predictPoint(~inputBufNormed, ~outputBufNormed, {
						~outputNorm.inverseTransformPoint(~outputBufNormed, ~outputBuf, {
							~outputBuf.loadToFloatArray(action: { |arr|
								defer { ~applyPrediction.(arr) };
								~predicting = false;
							});
						});
					});
				});
			};
		});
	};

	// ========== OSC RESPONDERS ==========
	(basePath +/+ "osc_responders.scd").load;
	s.sync;
	"[86BB] OSC responders loaded.".postln;

	s.sync;
	("[86BB] Ready. Model:" + if(~modelLoaded == true, "loaded", "none") ++ ". Output dims:" + nOutputDims + "(LED:" + nLedOutputDims + "+ Trans:" + nTransducerDims ++ ").").postln;
});
)
