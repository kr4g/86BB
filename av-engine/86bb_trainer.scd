// =====================================================
// 86BB Combined AV Trainer — FluCoMa MLP Regression
// Maps gut state bio-scores → LED params + transducer params.
//
// Workflow:
//   1. Design LED presets in 86bb_main.scd, save them
//   2. Design transducer presets in 86bb_transducer_main.scd, save them
//   3. Open this trainer
//   4. Select a gut state (cluster or manual)
//   5. Pick an LED preset and a transducer preset
//   6. Click "Add Pair" to add to the training dataset
//   7. Repeat for multiple gut states
//   8. Click "Train" to fit the MLP
//   9. Click "Test" to predict from the selected gut state
// =====================================================
(
~numLEDs = 5;
~nBioScores = 8;
~nTransducerDims = 43;
~espPort = SerialPort("/dev/tty.usbserial-0001", baudrate: 115200);
~slipSendOSC = { |port, addr, args|
	var end = 0xC0, esc = 0xDB, escEnd = 0xDC, escEsc = 0xDD;
	var raw = ([addr] ++ args).asRawOSC;
	port.put(end);
	raw.do { |byte|
		var b = byte.bitAnd(0xFF);
		case
		{ b == end } { port.put(esc); port.put(escEnd) }
		{ b == esc } { port.put(esc); port.put(escEsc) }
		{ port.put(b) };
	};
	port.put(end);
};

s.options.outDevice_(
	"MacBook Pro Speakers"
	// "UMC404HD 192k"
);
s.options.numOutputBusChannels_(4);
s.options.numInputBusChannels_(0);
s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));

s.waitForBoot({
	var basePath = thisProcess.nowExecutingPath.dirname;
	var modelsPath = basePath +/+ "models";
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	var canvas, mainLayout, scrollView;
	var allLedParams, channelLabels, nLedOutputDims, nOutputDims;
	var ledPresetsPath, ledPresets, ledPresetPopup, ledPresetLabel;
	var transPresetsPath, transPresets, transPresetPopup, transPresetLabel;
	var gutSelector, manualGutFields, pairCountLabel, errorLabel;
	var previewViews, previewActive = false;
	var pairCount = 0;

	// ========== CLUSTER BIO-SCORE DATA ==========
	~clusterLabels = [
		"0: Fermented Calm",      "1: Deep Green Vitality",
		"2: Carnivore Dysbiosis",  "3: Processed Fog",
		"4: Protein Baseline",     "5: Fiber Glow",
		"6: Moderate Balance",     "7: Sweet Ambivalence",
		"8: Ethanol Dissociation", "9: Stimulant Clarity",
		"10: Egg-Fiber Paradox",   "11: Starch Erosion",
		"12: Cosmopolitan Center", "13: Industrial Decline",
		"14: Peak Nourishment",    "15: Margarine Malaise",
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

	// ========== SYNTHDEFS ==========
	(basePath +/+ "synthdefs/leds.scd").load;
	(basePath +/+ "synthdefs/transducers.scd").load;
	s.sync;

	// ========== LED BUSES / SYNTHS ==========
	previewViews = Array.newClear(~numLEDs);
	~ledBus = Bus.control(s, ~numLEDs * 3);
	~freqBus = Bus.control(s, ~numLEDs * 3);
	~lfoGroup = Group.new;
	~collectorGroup = Group.after(~lfoGroup);
	~lfo = ~numLEDs.collect({ |i|
		Synth(\ledLFO, [\outBus, ~ledBus.index + (i * 3), \freqOutBus, ~freqBus.index + (i * 3), \wtBufStart, ~wtBufStart], ~lfoGroup);
	});
	~collector = Synth(\ledCollector, [\ledBusIndex, ~ledBus.index, \freqBusIndex, ~freqBus.index], ~collectorGroup);

	OSCdef(\ledForward, { |msg|
		var values = msg[3..];
		try { ~slipSendOSC.(~espPort, "/all", values) };
		if(previewActive == true, {
			defer {
				~numLEDs.do { |i|
					var ri = i * 3;
					if(previewViews[i].notNil and: { previewViews[i].isClosed.not }, {
						previewViews[i].background = Color(values[ri] ? 0, values[ri+1] ? 0, values[ri+2] ? 0);
					});
				};
			};
		});
	}, '/leds');

	// ========== TRANSDUCER SYNTHS ==========
	~drips = Synth(\drips, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~purrs = Synth(\purrs, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~burps = Synth(\burps, [\out, 0, \gain, -96]);
	s.sync;

	// ========== LED PARAM PACKING (must match 86bb_main / boot) ==========
	allLedParams = [\freq, \wave, \noiseFreq, \noise, \min, \max, \amFreq, \amWave, \amDepth];
	channelLabels = ["R", "G", "B"];
	nLedOutputDims = (~numLEDs * ((allLedParams.size * 3) + 1)) + 4;
	nOutputDims = nLedOutputDims + ~nTransducerDims;

	// ========== TRANSDUCER PARAM PACKING (must match 86bb_transducer_main / boot) ==========
	~dripsFlat = [\prob1, \prob2, \wtPos1, \wtPos2, \amRate1, \amRate2, \amMul1, \amMul2,
		\freqWtPos1, \freqWtPos2, \freqRate1, \freqRate2, \sweepLo, \sweepHi, \hpFreq, \gain];
	~purrsFlat = [\freqMin1, \freqMin2, \freqMax1, \freqMax2, \freqWtPos1, \freqWtPos2,
		\freqRate1, \freqRate2, \width1, \width2, \wtPos1, \wtPos2,
		\amRate1, \amRate2, \amMul1, \amMul2, \lpFreq1, \lpFreq2, \gain];
	~burpsFlat = [\trigRate1, \trigRate2, \fund, \sweepHiMin, \sweepHiMax, \formantBW, \combMix, \gain];

	("[86BB Trainer] Output dims:" + nOutputDims + "(LED:" + nLedOutputDims + "+ Trans:" + ~nTransducerDims ++ ")").postln;

	// ========== PRESET LOADING ==========
	~loadDictFromFile = { |path| if(File.exists(path), { File.readAllString(path).interpret ? Dictionary.new }, { Dictionary.new }) };

	ledPresetsPath = basePath +/+ "presets/led_presets.scd";
	transPresetsPath = basePath +/+ "presets/transducer_presets.scd";
	ledPresets = ~loadDictFromFile.(ledPresetsPath);
	transPresets = ~loadDictFromFile.(transPresetsPath);

	// ========== PRESET → ARRAY CONVERSION ==========
	~ledPresetToArray = { |presetDict|
		var arr = Array.new(nLedOutputDims);
		~numLEDs.do { |led|
			allLedParams.do { |group|
				3.do { |ci|
					arr = arr.add(presetDict[("led" ++ led ++ "_" ++ group ++ channelLabels[ci]).asSymbol] ? 0);
				};
			};
			arr = arr.add(presetDict[("led" ++ led ++ "_brightness").asSymbol] ? 1.0);
		};
		arr = arr.add(presetDict[\gamma] ? 1.8);
		arr = arr.add(presetDict[\rateMultiplier] ? 5);
		arr = arr.add(presetDict[\minRate] ? 5);
		arr = arr.add(presetDict[\maxRate] ? 30);
		arr;
	};

	~transPresetToArray = { |presetDict|
		var arr = Array.new(~nTransducerDims);
		[[\drips, ~dripsFlat], [\purrs, ~purrsFlat], [\burps, ~burpsFlat]].do { |pair|
			var synthName = pair[0];
			pair[1].do { |param|
				arr = arr.add(presetDict[(synthName ++ "_" ++ param).asSymbol] ? 0);
			};
		};
		arr;
	};

	// ========== APPLY PREDICTIONS TO LIVE SYNTHS ==========
	~applyLedPrediction = { |arr|
		var idx = 0;
		~numLEDs.do { |led|
			allLedParams.do { |group|
				3.do { |ci|
					~lfo[led].set((group ++ channelLabels[ci]).asSymbol, arr[idx]);
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
	};

	~applyTransPrediction = { |arr|
		var idx = 0;
		[[\drips, ~dripsFlat, ~drips], [\purrs, ~purrsFlat, ~purrs], [\burps, ~burpsFlat, ~burps]].do { |triple|
			triple[1].do { |param|
				triple[2].set(param, arr[idx]);
				idx = idx + 1;
			};
		};
	};

	~applyLedPresetToSynths = { |presetDict|
		~applyLedPrediction.(~ledPresetToArray.(presetDict));
	};

	~applyTransPresetToSynths = { |presetDict|
		~applyTransPrediction.(~transPresetToArray.(presetDict));
	};

	// ========== FLUCOMA SETUP ==========
	~inputDS = FluidDataSet(s);
	~outputDS = FluidDataSet(s);
	~inputDSNormed = FluidDataSet(s);
	~outputDSNormed = FluidDataSet(s);
	~inputNorm = FluidNormalize(s);
	~outputNorm = FluidNormalize(s);
	~mlp = FluidMLPRegressor(s, hiddenLayers: [64, 32], activation: FluidMLPRegressor.sigmoid, maxIter: 100, learnRate: 0.01, batchSize: 1);
	~inputBuf = Buffer.alloc(s, ~nBioScores);
	~outputBuf = Buffer.alloc(s, nOutputDims);
	~inputBufNormed = Buffer.alloc(s, ~nBioScores);
	~outputBufNormed = Buffer.alloc(s, nOutputDims);
	s.sync;

	~getSelectedGutState = {
		var idx = gutSelector.value - 1;
		if(idx >= 0, { ~clusterBioScores[idx] }, { manualGutFields.collect(_.value) });
	};

	~addPair = {
		var gutState = ~getSelectedGutState.value;
		var ledIdx = ledPresetPopup.value - 1;
		var transIdx = transPresetPopup.value - 1;
		if(ledIdx < 0, {
			"[86BB Trainer] Select an LED preset first.".postln;
		}, {
			if(transIdx < 0, {
				"[86BB Trainer] Select a transducer preset first.".postln;
			}, {
				var ledName = ledPresetPopup.items[ledPresetPopup.value];
				var transName = transPresetPopup.items[transPresetPopup.value];
				var ledArr = ~ledPresetToArray.(ledPresets[ledName]);
				var transArr = ~transPresetToArray.(transPresets[transName]);
				var combinedArr = ledArr ++ transArr;
				var id = "pair_" ++ pairCount;
				fork {
					~inputBuf.loadCollection(gutState);
					~outputBuf.loadCollection(combinedArr);
					s.sync;
					~inputDS.addPoint(id, ~inputBuf);
					~outputDS.addPoint(id, ~outputBuf);
					pairCount = pairCount + 1;
					defer { pairCountLabel.string = "Pairs:" + pairCount };
					("[86BB Trainer] Added pair" + id + "— gut:" + gutState.round(0.001)
						+ "→ LED:" + ledName + "+ Trans:" + transName).postln;
				};
			});
		});
	};

	~trainMLP = {
		~inputNorm.fitTransform(~inputDS, ~inputDSNormed, {
			~outputNorm.fitTransform(~outputDS, ~outputDSNormed, {
				var doTrain;
				~trainingActive = true;
				doTrain = {
					~mlp.fit(~inputDSNormed, ~outputDSNormed, { |error|
						defer { errorLabel.string = "Loss:" + error.round(0.00001) };
						("[86BB Trainer] loss:" + error).postln;
						if(~trainingActive, { doTrain.() });
					});
				};
				doTrain.();
			});
		});
	};

	~stopTraining = { ~trainingActive = false };

	~testPredict = {
		var gutState = ~getSelectedGutState.value;
		fork {
			~inputBuf.loadCollection(gutState);
			s.sync;
			~inputNorm.transformPoint(~inputBuf, ~inputBufNormed, {
				~mlp.predictPoint(~inputBufNormed, ~outputBufNormed, {
					~outputNorm.inverseTransformPoint(~outputBufNormed, ~outputBuf, {
						~outputBuf.loadToFloatArray(action: { |arr|
							defer {
								~applyLedPrediction.(arr[0..nLedOutputDims-1]);
								~applyTransPrediction.(arr[nLedOutputDims..]);
							};
							("[86BB Trainer] Predicted for gut:" + gutState.round(0.001)).postln;
						});
					});
				});
			});
		};
	};

	~saveModel = {
		~mlp.write(modelsPath +/+ "av_mlp.json");
		~inputNorm.write(modelsPath +/+ "av_input_norm.json");
		~outputNorm.write(modelsPath +/+ "av_output_norm.json");
		"[86BB Trainer] Model + normalizers saved.".postln;
	};

	~loadModel = {
		~mlp.read(modelsPath +/+ "av_mlp.json");
		~inputNorm.read(modelsPath +/+ "av_input_norm.json");
		~outputNorm.read(modelsPath +/+ "av_output_norm.json");
		"[86BB Trainer] Model + normalizers loaded.".postln;
	};

	~saveDataset = {
		~inputDS.write(modelsPath +/+ "av_input_ds.json");
		~outputDS.write(modelsPath +/+ "av_output_ds.json");
		"[86BB Trainer] Datasets saved.".postln;
	};

	~loadDataset = {
		fork {
			~inputDS.read(modelsPath +/+ "av_input_ds.json");
			~outputDS.read(modelsPath +/+ "av_output_ds.json");
			s.sync;
			~inputDS.size({ |sz| pairCount = sz; defer { pairCountLabel.string = "Pairs:" + pairCount } });
			"[86BB Trainer] Datasets loaded.".postln;
		};
	};

	~refreshPresets = {
		ledPresets = ~loadDictFromFile.(ledPresetsPath);
		transPresets = ~loadDictFromFile.(transPresetsPath);
		defer {
			ledPresetPopup.items = ["(select LED preset)"] ++ ledPresets.keys.asArray.sort;
			ledPresetPopup.value = 0;
			ledPresetLabel.string = "--";
			transPresetPopup.items = ["(select transducer preset)"] ++ transPresets.keys.asArray.sort;
			transPresetPopup.value = 0;
			transPresetLabel.string = "--";
		};
		"[86BB Trainer] Presets refreshed.".postln;
	};

	// ========== BUILD WINDOW ==========
	~trainerWin = Window("86BB AV Trainer", Rect(50, 50, 800, 500)).front;
	canvas = View();
	mainLayout = VLayout().margins_(6).spacing_(4);
	canvas.layout = mainLayout;

	mainLayout.add(View().fixedHeight_(20).layout_(HLayout(
		StaticText().string_("══ 86BB Combined AV Trainer ══").stringColor_(Color(0.5, 0.7, 1.0)), nil
	).margins_(0).spacing_(4)));

	// --- LED Preview ---
	{ var items = List.new;
		var toggleBtn = Button().states_([
			["Preview ON", Color.white, Color(0.3, 0.5, 0.3)],
			["Preview OFF", Color.white, Color.gray(0.35)]
		]).fixedWidth_(80);
		toggleBtn.action = { |b|
			previewActive = (b.value == 0);
			if(previewActive.not, { ~numLEDs.do { |i| previewViews[i].background = Color.gray(0.15) } });
		};
		items.add(toggleBtn);
		~numLEDs.do { |i| var pv = View().background_(Color.gray(0.15)); previewViews[i] = pv; items.add(pv) };
		mainLayout.add(View().fixedHeight_(36).layout_(HLayout(*items).margins_(0).spacing_(4)));
	}.value;

	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- LED preset selector ---
	ledPresetLabel = StaticText().string_("--").fixedWidth_(60);
	ledPresetPopup = PopUpMenu().items_(["(select LED preset)"] ++ ledPresets.keys.asArray.sort).fixedWidth_(220);
	ledPresetPopup.action = { |v|
		if(v.value > 0, {
			var name = v.items[v.value];
			if(ledPresets[name].notNil, {
				~applyLedPresetToSynths.(ledPresets[name]);
				ledPresetLabel.string = name;
				("Loaded LED preset:" + name).postln;
			});
		}, {
			ledPresetLabel.string = "--";
		});
	};

	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("LED Preset:").fixedWidth_(110),
		ledPresetPopup, ledPresetLabel, nil
	).margins_(0).spacing_(4)));

	// --- Transducer preset selector ---
	transPresetLabel = StaticText().string_("--").fixedWidth_(60);
	transPresetPopup = PopUpMenu().items_(["(select transducer preset)"] ++ transPresets.keys.asArray.sort).fixedWidth_(220);
	transPresetPopup.action = { |v|
		if(v.value > 0, {
			var name = v.items[v.value];
			if(transPresets[name].notNil, {
				~applyTransPresetToSynths.(transPresets[name]);
				transPresetLabel.string = name;
				("Loaded transducer preset:" + name).postln;
			});
		}, {
			transPresetLabel.string = "--";
		});
	};

	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("Transducer Preset:").fixedWidth_(110),
		transPresetPopup, transPresetLabel, nil
	).margins_(0).spacing_(4)));

	// --- Refresh presets button ---
	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("").fixedWidth_(110),
		Button().states_([["Refresh Presets", Color.white, Color.gray(0.45)]]).fixedWidth_(120).action_({ ~refreshPresets.value }),
		nil
	).margins_(0).spacing_(4)));

	mainLayout.add(View().fixedHeight_(4).background_(Color(0.3, 0.5, 0.8)));

	// --- Gut state selector ---
	mainLayout.add(View().fixedHeight_(20).layout_(HLayout(
		StaticText().string_("══ FluCoMa MLP Training ══").stringColor_(Color(0.5, 0.7, 1.0)), nil
	).margins_(0).spacing_(4)));

	gutSelector = PopUpMenu().items_(["(manual entry)"] ++ ~clusterLabels).fixedWidth_(250);
	manualGutFields = ~nBioScores.collect({ NumberBox().fixedWidth_(55).decimals_(4).value_(0) });
	mainLayout.add(View().fixedHeight_(26).layout_(HLayout(
		StaticText().string_("Gut State:").fixedWidth_(70),
		gutSelector,
		*manualGutFields
	).margins_(0).spacing_(4)));

	// --- Training controls ---
	pairCountLabel = StaticText().string_("Pairs: 0").fixedWidth_(80);
	errorLabel = StaticText().string_("Loss: --").fixedWidth_(150);

	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["Add Pair", Color.white, Color(0.2, 0.6, 0.3)]]).fixedWidth_(80).action_({ ~addPair.value }),
		pairCountLabel,
		Button().states_([["Train", Color.white, Color(0.3, 0.45, 0.8)]]).fixedWidth_(60).action_({ ~trainMLP.value }),
		Button().states_([["Stop", Color.white, Color(0.7, 0.3, 0.3)]]).fixedWidth_(50).action_({ ~stopTraining.value }),
		errorLabel,
		Button().states_([["Test", Color.white, Color(0.6, 0.4, 0.8)]]).fixedWidth_(60).action_({ ~testPredict.value }),
		nil
	).margins_(2).spacing_(4)));

	// --- Save/Load ---
	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["Save Model", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~saveModel.value }),
		Button().states_([["Load Model", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~loadModel.value }),
		Button().states_([["Save Dataset", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~saveDataset.value }),
		Button().states_([["Load Dataset", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~loadDataset.value }),
		nil
	).margins_(2).spacing_(4)));

	// --- Pair list info ---
	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));
	mainLayout.add(View().fixedHeight_(20).layout_(HLayout(
		StaticText().string_("Output dims:" + nOutputDims + "(LED:" + nLedOutputDims + "+ Trans:" + ~nTransducerDims ++ ")").stringColor_(Color.gray(0.6)),
		nil
	).margins_(0).spacing_(4)));

	mainLayout.add(nil);

	scrollView = ScrollView(~trainerWin, ~trainerWin.view.bounds).canvas_(canvas);
	scrollView.resize = 5;
	~trainerWin.view.onResize_({ |view| scrollView.bounds = view.bounds });

	~trainerWin.onClose_({
		previewActive = false;
		~trainingActive = false;
		OSCdef(\ledForward).free;
		~lfo.do(_.free);
		~collector.free;
		~lfoGroup.free; ~collectorGroup.free;
		~ledBus.free; ~freqBus.free;
		~drips.set(\gate, 0);
		~purrs.set(\gate, 0);
		~burps.set(\gate, 0);
		~wtBufs.do(_.free);
		[~inputBuf, ~outputBuf, ~inputBufNormed, ~outputBufNormed].do(_.free);
		try { ~slipSendOSC.(~espPort, "/all", 0.dup(~numLEDs * 3)) };
		try { ~espPort.close };
		"[86BB Trainer] Closed.".postln;
	});

	previewActive = true;
	"[86BB Trainer] Ready. Output dims:" + nOutputDims ++ ".".postln;
});
)
