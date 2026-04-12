// =====================================================
// 86BB LED Trainer — FluCoMa MLP Regression
// Design LED presets for gut state bio-scores, then train
// a neural network to map between them.
//
// Workflow:
//   1. Select a gut state from the cluster menu
//   2. Dial in the LED preset you want for that state
//   3. Click "Add Pair" to add to the training dataset
//   4. Repeat for multiple gut states
//   5. Click "Train" to fit the MLP
//   6. Click "Test" to predict from the selected gut state
// =====================================================
(
~numLEDs = 5;
~nBioScores = 8;
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

s.waitForBoot({
	var basePath = thisProcess.nowExecutingPath.dirname;
	var modelsPath = basePath +/+ "models";
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	var canvas, mainLayout, scrollView;
	var baseParams, amParams, allParams, paramSpecs, defaults, colors, channelLabels;
	var sliders, numberBoxes, brightSliders, brightBoxes, muteButtons;
	var presetPopup, presetNameField, presetsPath, presets;
	var previewViews, previewActive = false;
	var gutSelector, pairCountLabel, errorLabel, manualGutFields;
	var nOutputDims, paramOrder;
	var pairCount = 0;

	// ========== CLUSTER BIO-SCORE DATA ==========
	~clusterLabels = [
		"0: Fermented Calm",
		"1: Deep Green Vitality",
		"2: Carnivore Dysbiosis",
		"3: Processed Fog",
		"4: Protein Baseline",
		"5: Fiber Glow",
		"6: Moderate Balance",
		"7: Sweet Ambivalence",
		"8: Ethanol Dissociation",
		"9: Stimulant Clarity",
		"10: Egg-Fiber Paradox",
		"11: Starch Erosion",
		"12: Cosmopolitan Center",
		"13: Industrial Decline",
		"14: Peak Nourishment",
		"15: Margarine Malaise",
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
	s.sync;

	// ========== BUSES / GROUPS / SYNTHS ==========
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
	s.sync;

	// ========== PARAM DEFINITIONS ==========
	baseParams = [\freq, \wave, \noiseFreq, \noise, \min, \max];
	amParams = [\amFreq, \amWave, \amDepth];
	allParams = baseParams ++ amParams;
	channelLabels = ["R", "G", "B"];
	paramSpecs = (
		freq: [0.01, 10.0, \exp, 0, 0.15].asSpec, wave: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		noiseFreq: [0.01, 10.0, \exp, 0, 0.15].asSpec, noise: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		min: [0.0, 1.0, \lin, 0, 0.0].asSpec, max: [0.0, 1.0, \lin, 0, 1.0].asSpec,
		amFreq: [0.01, 20.0, \exp, 0, 1.0].asSpec, amWave: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		amDepth: [0.0, 1.0, \lin, 0, 0.0].asSpec,
	);
	defaults = (freq: 0.15, wave: 0.0, noiseFreq: 0.15, noise: 0.0, min: 0.0, max: 1.0, amFreq: 1.0, amWave: 0.0, amDepth: 0.0);
	colors = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1)];
	previewViews = Array.newClear(~numLEDs);

	sliders = Array.fill(~numLEDs, { Array.fill(allParams.size, { Array.newClear(3) }) });
	numberBoxes = Array.fill(~numLEDs, { Array.fill(allParams.size, { Array.newClear(3) }) });
	brightSliders = Array.newClear(~numLEDs);
	brightBoxes = Array.newClear(~numLEDs);
	muteButtons = Array.newClear(~numLEDs);

	presetsPath = basePath +/+ "presets/led_presets.scd";
	~bb86 = ();

	// ========== PARAMETER PACKING ORDER ==========
	paramOrder = allParams.collect({ |group| channelLabels.collect({ |ch| (group ++ ch).asSymbol }) }).flatten;
	nOutputDims = (~numLEDs * (paramOrder.size + 1)) + 4;
	("[86BB Trainer] Output dims:" + nOutputDims + "(" ++ ~numLEDs + "LEDs x" + (paramOrder.size + 1) + "params + 4 globals)").postln;

	~bb86[\getStateAsArray] = {
		var arr = Array.new(nOutputDims);
		~numLEDs.do { |led|
			allParams.do { |group, gi|
				3.do { |ci| arr = arr.add(numberBoxes[led][gi][ci].value) };
			};
			arr = arr.add(brightBoxes[led].value);
		};
		arr = arr.add(~bb86[\gammaBox].value);
		arr = arr.add(~bb86[\rateMulBox].value);
		arr = arr.add(~bb86[\minRateBox].value);
		arr = arr.add(~bb86[\maxRateBox].value);
		arr;
	};

	~bb86[\applyStateFromArray] = { |arr|
		var idx = 0;
		~numLEDs.do { |led|
			allParams.do { |group, gi|
				var spec = paramSpecs[group];
				3.do { |ci|
					var val = arr[idx];
					var key = (group ++ channelLabels[ci]).asSymbol;
					sliders[led][gi][ci].value = spec.unmap(val);
					numberBoxes[led][gi][ci].value = val;
					~lfo[led].set(key, val);
					idx = idx + 1;
				};
			};
			{ var bval = arr[idx];
				brightSliders[led].value = bval;
				brightBoxes[led].value = bval;
				~lfo[led].set(\brightness, bval);
				idx = idx + 1;
			}.value;
		};
		~bb86[\gammaBox].valueAction_(arr[idx]); idx = idx + 1;
		~bb86[\rateMulBox].valueAction_(arr[idx]); idx = idx + 1;
		~bb86[\minRateBox].valueAction_(arr[idx]); idx = idx + 1;
		~bb86[\maxRateBox].valueAction_(arr[idx]);
	};

	// ========== PRESET HELPERS (same as 86bb_main) ==========
	~bb86[\saveDictToFile] = { |dict, path| var file = File(path, "w"); file.write(dict.asCompileString); file.close };
	~bb86[\loadDictFromFile] = { |path| if(File.exists(path), { File.readAllString(path).interpret ? Dictionary.new }, { Dictionary.new }) };
	~bb86[\getCurrentState] = {
		var state = Dictionary.new;
		~numLEDs.do { |led|
			allParams.do { |group, gi| 3.do { |ci|
				state[("led" ++ led ++ "_" ++ group ++ channelLabels[ci]).asSymbol] = numberBoxes[led][gi][ci].value;
			}};
			state[("led" ++ led ++ "_brightness").asSymbol] = brightBoxes[led].value;
		};
		state[\gamma] = ~bb86[\gammaBox].value;
		state[\rateMultiplier] = ~bb86[\rateMulBox].value;
		state[\minRate] = ~bb86[\minRateBox].value;
		state[\maxRate] = ~bb86[\maxRateBox].value;
		state;
	};
	~bb86[\applyPreset] = { |state|
		~numLEDs.do { |led|
			allParams.do { |group, gi| var spec = paramSpecs[group]; 3.do { |ci|
				var val = state[("led" ++ led ++ "_" ++ group ++ channelLabels[ci]).asSymbol];
				if(val.notNil, { sliders[led][gi][ci].value = spec.unmap(val); numberBoxes[led][gi][ci].value = val; ~lfo[led].set((group ++ channelLabels[ci]).asSymbol, val) });
			}};
			{ var bval = state[("led" ++ led ++ "_brightness").asSymbol];
				if(bval.notNil, { brightSliders[led].value = bval; brightBoxes[led].value = bval; ~lfo[led].set(\brightness, bval) });
			}.value;
		};
		if(state[\gamma].notNil, { ~bb86[\gammaBox].valueAction_(state[\gamma]) });
		if(state[\rateMultiplier].notNil, { ~bb86[\rateMulBox].valueAction_(state[\rateMultiplier]) });
		if(state[\minRate].notNil, { ~bb86[\minRateBox].valueAction_(state[\minRate]) });
		if(state[\maxRate].notNil, { ~bb86[\maxRateBox].valueAction_(state[\maxRate]) });
	};
	~bb86[\updatePresetMenu] = { presetPopup.items = ["(select preset)"] ++ presets.keys.asArray.sort; presetPopup.value = 0 };
	presets = ~bb86[\loadDictFromFile].(presetsPath);

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
		if(idx >= 0, {
			~clusterBioScores[idx];
		}, {
			manualGutFields.collect(_.value);
		});
	};

	~bb86[\addPair] = {
		var gutState = ~getSelectedGutState.value;
		var ledState = ~bb86[\getStateAsArray].value;
		var id = "pair_" ++ pairCount;
		fork {
			~inputBuf.loadCollection(gutState);
			~outputBuf.loadCollection(ledState);
			s.sync;
			~inputDS.addPoint(id, ~inputBuf);
			~outputDS.addPoint(id, ~outputBuf);
			pairCount = pairCount + 1;
			defer { pairCountLabel.string = "Pairs:" + pairCount };
			("[86BB Trainer] Added pair" + id + "— gut:" + gutState.round(0.001)).postln;
		};
	};

	~bb86[\trainMLP] = {
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

	~bb86[\stopTraining] = { ~trainingActive = false };

	~bb86[\testPredict] = {
		var gutState = ~getSelectedGutState.value;
		fork {
			~inputBuf.loadCollection(gutState);
			s.sync;
			~inputNorm.transformPoint(~inputBuf, ~inputBufNormed, {
				~mlp.predictPoint(~inputBufNormed, ~outputBufNormed, {
					~outputNorm.inverseTransformPoint(~outputBufNormed, ~outputBuf, {
						~outputBuf.loadToFloatArray(action: { |arr|
							defer { ~bb86[\applyStateFromArray].(arr) };
							("[86BB Trainer] Predicted for gut:" + gutState.round(0.001)).postln;
						});
					});
				});
			});
		};
	};

	~bb86[\saveModel] = {
		~mlp.write(modelsPath +/+ "led_mlp.json");
		~inputNorm.write(modelsPath +/+ "led_input_norm.json");
		~outputNorm.write(modelsPath +/+ "led_output_norm.json");
		"[86BB Trainer] Model + normalizers saved.".postln;
	};

	~bb86[\loadModel] = {
		~mlp.read(modelsPath +/+ "led_mlp.json");
		~inputNorm.read(modelsPath +/+ "led_input_norm.json");
		~outputNorm.read(modelsPath +/+ "led_output_norm.json");
		"[86BB Trainer] Model + normalizers loaded.".postln;
	};

	~bb86[\saveDataset] = {
		~inputDS.write(modelsPath +/+ "led_input_ds.json");
		~outputDS.write(modelsPath +/+ "led_output_ds.json");
		"[86BB Trainer] Datasets saved.".postln;
	};

	~bb86[\loadDataset] = {
		fork {
			~inputDS.read(modelsPath +/+ "led_input_ds.json");
			~outputDS.read(modelsPath +/+ "led_output_ds.json");
			s.sync;
			~inputDS.size({ |sz| pairCount = sz; defer { pairCountLabel.string = "Pairs:" + pairCount } });
			"[86BB Trainer] Datasets loaded.".postln;
		};
	};

	// ========== BUILD WINDOW ==========
	~bb86[\win] = Window("86BB LED Trainer", Rect(50, 50, 1400, 950)).front;
	canvas = View();
	mainLayout = VLayout().margins_(4).spacing_(2);
	canvas.layout = mainLayout;

	// --- Preset bar ---
	presetPopup = PopUpMenu().items_(["(select preset)"] ++ presets.keys.asArray.sort).fixedWidth_(180);
	presetPopup.action = { |v| if(v.value > 0, { ~bb86[\applyPreset].(presets[v.items[v.value]]); ("Loaded:" + v.items[v.value]).postln }) };
	presetNameField = TextField().string_("preset1").fixedWidth_(120);
	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("Preset:").fixedWidth_(45), presetPopup, presetNameField,
		Button().states_([["+", Color.white, Color(0.2, 0.4, 0.8)]]).fixedWidth_(28).action_({
			var name = presetNameField.string;
			if(name.size > 0, { presets[name] = ~bb86[\getCurrentState].value; ~bb86[\updatePresetMenu].value; ~bb86[\saveDictToFile].(presets, presetsPath); ("Saved:" + name).postln });
		}),
		Button().states_([["-", Color.white, Color(0.8, 0.25, 0.25)]]).fixedWidth_(28).action_({
			var idx = presetPopup.value;
			if(idx > 0, { presets.removeAt(presetPopup.items[idx]); ~bb86[\updatePresetMenu].value; ~bb86[\saveDictToFile].(presets, presetsPath) });
		}), nil
	).margins_(2).spacing_(4)));
	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- Preview row ---
	{ var items = List.new;
		var toggleBtn = Button().states_([["Preview ON", Color.white, Color(0.3, 0.5, 0.3)], ["Preview OFF", Color.white, Color.gray(0.35)]]).fixedWidth_(70);
		toggleBtn.action = { |b| previewActive = (b.value == 0); if(previewActive.not, { ~numLEDs.do { |i| previewViews[i].background = Color.gray(0.15) } }) };
		previewActive = true;
		items.add(toggleBtn);
		~numLEDs.do { |i| var pv = View().background_(Color.gray(0.15)); previewViews[i] = pv; items.add(pv) };
		mainLayout.add(View().fixedHeight_(40).layout_(HLayout(*items).margins_(0).spacing_(4)));
	}.value;

	// --- LED headers ---
	{ var items = List.new;
		items.add(StaticText().string_("").fixedWidth_(70));
		~numLEDs.do { |i| items.add(StaticText().string_("LED" + (i+1)).align_(\center)) };
		mainLayout.add(View().fixedHeight_(18).layout_(HLayout(*items).margins_(0).spacing_(4)));
	}.value;

	// --- Param rows helper ---
	~bb86[\addParamSection] = { |label, paramList, startIndex|
		mainLayout.add(View().fixedHeight_(18).layout_(HLayout(StaticText().string_(label).stringColor_(Color.gray(0.7)), nil).margins_(0).spacing_(4)));
		paramList.do { |group, localGi|
			var gi = startIndex + localGi;
			var spec = paramSpecs[group];
			var defVal = defaults[group];
			mainLayout.add(View().fixedHeight_(16).layout_(HLayout(StaticText().string_(group.asString.toUpper).fixedWidth_(70), nil).margins_(0).spacing_(4)));
			3.do { |ci|
				var rowItems = List.new;
				var key = (group ++ channelLabels[ci]).asSymbol;
				rowItems.add(View().fixedWidth_(70).background_(colors[ci].alpha_(0.35)));
				~numLEDs.do { |led|
					var slider = Slider().orientation_(\horizontal).value_(spec.unmap(defVal)).background_(colors[ci].alpha_(0.3));
					var numBox = NumberBox().fixedWidth_(40).decimals_(3).value_(defVal);
					slider.action = { |sl| var val = spec.map(sl.value); numBox.value = val; ~lfo[led].set(key, val) };
					numBox.action = { |nb| var val = nb.value.clip(spec.minval, spec.maxval); slider.value = spec.unmap(val); ~lfo[led].set(key, val) };
					sliders[led][gi][ci] = slider; numberBoxes[led][gi][ci] = numBox;
					rowItems.add(slider); rowItems.add(numBox);
				};
				mainLayout.add(View().fixedHeight_(22).layout_(HLayout(*rowItems).margins_(0).spacing_(4)));
			};
		};
	};
	~bb86[\addParamSection].("--- Base LFO ---", baseParams, 0);
	~bb86[\addParamSection].("--- AM LFO ---", amParams, baseParams.size);

	// --- Brightness + Mute ---
	mainLayout.add(View().fixedHeight_(18).layout_(HLayout(StaticText().string_("--- Per LED ---").stringColor_(Color.gray(0.7)), nil).margins_(0).spacing_(4)));
	mainLayout.add(View().fixedHeight_(16).layout_(HLayout(StaticText().string_("BRIGHT").fixedWidth_(70), nil).margins_(0).spacing_(4)));
	{ var rowItems = List.new;
		rowItems.add(StaticText().string_("").fixedWidth_(70));
		~numLEDs.do { |led|
			var bSlider = Slider().orientation_(\horizontal).value_(1.0);
			var bBox = NumberBox().fixedWidth_(40).decimals_(2).value_(1.0);
			bSlider.action = { |sl| bBox.value = sl.value; ~lfo[led].set(\brightness, sl.value) };
			bBox.action = { |nb| var v = nb.value.clip(0,1); bSlider.value = v; ~lfo[led].set(\brightness, v) };
			brightSliders[led] = bSlider; brightBoxes[led] = bBox;
			rowItems.add(bSlider); rowItems.add(bBox);
		};
		mainLayout.add(View().fixedHeight_(22).layout_(HLayout(*rowItems).margins_(0).spacing_(4)));
	}.value;
	{ var rowItems = List.new;
		rowItems.add(StaticText().string_("MUTE").fixedWidth_(70));
		~numLEDs.do { |led|
			var btn = Button().states_([["M", Color.white, Color.gray(0.4)], ["M", Color.white, Color(0.8, 0.2, 0.2)]]).fixedWidth_(30);
			btn.action = { |b| ~lfo[led].set(\mute, b.value) };
			muteButtons[led] = btn; rowItems.add(btn); rowItems.add(nil);
		};
		mainLayout.add(View().fixedHeight_(26).layout_(HLayout(*rowItems).margins_(0).spacing_(4)));
	}.value;
	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- Globals ---
	[\gamma, \lagTime, \rateMult, \minRate, \maxRate].do { |which|
		var labelStr, spec, defVal, setter, slider, numBox;
		switch(which,
			\gamma, { labelStr = "Gamma"; spec = [0.5, 3.0, \lin, 0, 1.8].asSpec; defVal = 1.8; setter = { |val| ~collector.set(\gamma, val) } },
			\lagTime, { labelStr = "Lag Time"; spec = [0.0, 5.0, \lin, 0, 2.0].asSpec; defVal = 2.0; setter = { |val| ~lfo.do { |sy| sy.set(\lagTime, val) } } },
			\rateMult, { labelStr = "Rate Mult"; spec = [1, 10, \lin, 0.1, 5].asSpec; defVal = 5; setter = { |val| ~collector.set(\rateMultiplier, val) } },
			\minRate, { labelStr = "Min Rate"; spec = [1, 30, \lin, 0.5, 5].asSpec; defVal = 5; setter = { |val| ~collector.set(\minRate, val) } },
			\maxRate, { labelStr = "Max Rate"; spec = [5, 60, \lin, 0.5, 30].asSpec; defVal = 30; setter = { |val| ~collector.set(\maxRate, val) } }
		);
		slider = Slider().orientation_(\horizontal).value_(spec.unmap(defVal));
		numBox = NumberBox().fixedWidth_(50).decimals_(2).value_(defVal);
		slider.action = { |sl| var val = spec.map(sl.value); numBox.value = val; setter.(val) };
		numBox.action = { |nb| var val = nb.value.clip(spec.minval, spec.maxval); slider.value = spec.unmap(val); setter.(val) };
		switch(which,
			\gamma, { ~bb86[\gammaSlider] = slider; ~bb86[\gammaBox] = numBox },
			\rateMult, { ~bb86[\rateMulSlider] = slider; ~bb86[\rateMulBox] = numBox },
			\minRate, { ~bb86[\minRateSlider] = slider; ~bb86[\minRateBox] = numBox },
			\maxRate, { ~bb86[\maxRateSlider] = slider; ~bb86[\maxRateBox] = numBox }
		);
		mainLayout.add(View().fixedHeight_(24).layout_(HLayout(StaticText().string_(labelStr).fixedWidth_(70), slider, numBox).margins_(0).spacing_(4)));
	};

	// --- Action buttons ---
	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["All Off", Color.white, Color(0.6, 0.2, 0.2)]]).action_({
			~numLEDs.do { |led| ~lfo[led].set(\brightness, 0); brightSliders[led].value = 0; brightBoxes[led].value = 0 };
			try { ~slipSendOSC.(~espPort, "/all", 0.dup(~numLEDs * 3)) };
		}),
		Button().states_([["Reset Defaults", Color.white, Color(0.3, 0.45, 0.65)]]).action_({
			~numLEDs.do { |led|
				allParams.do { |group, gi| var spec = paramSpecs[group]; var defVal = defaults[group]; 3.do { |ci|
					sliders[led][gi][ci].value = spec.unmap(defVal); numberBoxes[led][gi][ci].value = defVal;
					~lfo[led].set((group ++ channelLabels[ci]).asSymbol, defVal);
				}};
				brightSliders[led].value = 1.0; brightBoxes[led].value = 1.0; ~lfo[led].set(\brightness, 1.0);
				if(muteButtons[led].value != 0, { muteButtons[led].value = 0; ~lfo[led].set(\mute, 0) });
			};
			~bb86[\gammaBox].valueAction_(1.8); ~bb86[\rateMulBox].valueAction_(5); ~bb86[\minRateBox].valueAction_(5); ~bb86[\maxRateBox].valueAction_(30);
		}), nil
	).margins_(2).spacing_(4)));

	mainLayout.add(View().fixedHeight_(4).background_(Color(0.3, 0.5, 0.8)));

	// ========== FLUCOMA TRAINING PANEL ==========
	mainLayout.add(View().fixedHeight_(20).layout_(HLayout(
		StaticText().string_("══ FluCoMa MLP Training ══").stringColor_(Color(0.5, 0.7, 1.0)), nil
	).margins_(0).spacing_(4)));

	// --- Gut state selector ---
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
		Button().states_([["Add Pair", Color.white, Color(0.2, 0.6, 0.3)]]).fixedWidth_(80).action_({ ~bb86[\addPair].value }),
		pairCountLabel,
		Button().states_([["Train", Color.white, Color(0.3, 0.45, 0.8)]]).fixedWidth_(60).action_({ ~bb86[\trainMLP].value }),
		Button().states_([["Stop", Color.white, Color(0.7, 0.3, 0.3)]]).fixedWidth_(50).action_({ ~bb86[\stopTraining].value }),
		errorLabel,
		Button().states_([["Test", Color.white, Color(0.6, 0.4, 0.8)]]).fixedWidth_(60).action_({ ~bb86[\testPredict].value }),
		nil
	).margins_(2).spacing_(4)));

	// --- Save/Load ---
	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["Save Model", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~bb86[\saveModel].value }),
		Button().states_([["Load Model", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~bb86[\loadModel].value }),
		Button().states_([["Save Dataset", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~bb86[\saveDataset].value }),
		Button().states_([["Load Dataset", Color.white, Color.gray(0.4)]]).fixedWidth_(90).action_({ ~bb86[\loadDataset].value }),
		nil
	).margins_(2).spacing_(4)));

	mainLayout.add(nil);

	scrollView = ScrollView(~bb86[\win], ~bb86[\win].view.bounds).canvas_(canvas);
	scrollView.resize = 5;
	~bb86[\win].view.onResize_({ |view| scrollView.bounds = view.bounds });

	~bb86[\win].onClose_({
		previewActive = false;
		~trainingActive = false;
		OSCdef(\ledForward).free;
		~lfo.do(_.free);
		~collector.free;
		~lfoGroup.free; ~collectorGroup.free;
		~ledBus.free; ~freqBus.free;
		~wtBufs.do(_.free);
		[~inputBuf, ~outputBuf, ~inputBufNormed, ~outputBufNormed].do(_.free);
		try { ~slipSendOSC.(~espPort, "/all", 0.dup(~numLEDs * 3)) };
		try { ~espPort.close };
		"[86BB Trainer] Closed.".postln;
	});

	"[86BB Trainer] Ready. Output dims:" + nOutputDims ++ ".".postln;
});
)
