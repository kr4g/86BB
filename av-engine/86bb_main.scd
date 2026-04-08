// =====================================================
// 86 Billion Butterflies — LED Test
// Evaluate this block to boot + open GUI.
// =====================================================
(
~numLEDs = 4;
~espAddr = NetAddr("192.168.8.124", 9000);

s.waitForBoot({
	var basePath = thisProcess.nowExecutingPath.dirname;
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	var canvas, mainLayout, scrollView;
	var baseParams, amParams, allParams, paramSpecs, defaults, colors, channelLabels;
	var sliders, numberBoxes, brightSliders, brightBoxes, muteButtons;
	var presetPopup, presetNameField, presetsPath, presets;
	var previewViews, previewActive = false;

	// ========== WAVETABLE BUFFERS (5: sine, tri, saw, square, guard) ==========
	~wtBufs = Buffer.allocConsecutive(5, s, sigSize * 2);
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
	4.do { |i| ~wtBufs[i].loadCollection(sigs[i].asWavetable) };
	~wtBufs[4].loadCollection(sqSig);
	s.sync;
	~wtBufStart = ~wtBufs[0].bufnum;
	("[86BB] Wavetable buffers ready (bufs" + ~wtBufStart + "-" + (~wtBufStart+4) ++ ")").postln;

	// ========== SYNTHDEFS ==========
	(basePath +/+ "synthdefs/led_synths.scd").load;
	s.sync;
	"[86BB] SynthDefs loaded.".postln;

	// ========== BUSES / GROUPS / SYNTHS ==========
	~ledBus = Bus.control(s, ~numLEDs * 3);
	~freqBus = Bus.control(s, ~numLEDs * 3);

	~lfoGroup = Group.new;
	~collectorGroup = Group.after(~lfoGroup);

	~lfo = ~numLEDs.collect({ |i|
		Synth(\ledLFO, [
			\outBus, ~ledBus.index + (i * 3),
			\freqOutBus, ~freqBus.index + (i * 3),
			\wtBufStart, ~wtBufStart
		], ~lfoGroup);
	});

	~collector = Synth(\ledCollector, [
		\ledBusIndex, ~ledBus.index,
		\freqBusIndex, ~freqBus.index
	], ~collectorGroup);

	OSCdef(\ledForward, { |msg|
		var values = msg[3..];
		try { ~espAddr.sendMsg("/all", *values) };
		if(previewActive == true, {
			defer {
				~numLEDs.do { |i|
					var ri = i * 3;
					if(previewViews[i].notNil and: { previewViews[i].isClosed.not }, {
						previewViews[i].background = Color(
							values[ri] ? 0,
							values[ri+1] ? 0,
							values[ri+2] ? 0
						);
					});
				};
			};
		});
	}, '/leds');

	s.sync;
	"[86BB] Synths ready.".postln;
	s.queryAllNodes;

	// ========== GUI SETUP ==========
	baseParams = [\freq, \wave, \noiseFreq, \noise, \min, \max];
	amParams = [\amFreq, \amWave, \amDepth];
	allParams = baseParams ++ amParams;
	channelLabels = ["R", "G", "B"];
	paramSpecs = (
		freq:      [0.01, 10.0, \exp, 0, 0.15].asSpec,
		wave:      [0.0, 1.0, \lin, 0, 0.0].asSpec,
		noiseFreq: [0.01, 10.0, \exp, 0, 0.15].asSpec,
		noise:     [0.0, 1.0, \lin, 0, 0.0].asSpec,
		min:       [0.0, 1.0, \lin, 0, 0.0].asSpec,
		max:       [0.0, 1.0, \lin, 0, 1.0].asSpec,
		amFreq:    [0.01, 20.0, \exp, 0, 1.0].asSpec,
		amWave:    [0.0, 1.0, \lin, 0, 0.0].asSpec,
		amDepth:   [0.0, 1.0, \lin, 0, 0.0].asSpec,
	);
	defaults = (
		freq: 0.15, wave: 0.0, noiseFreq: 0.15, noise: 0.0, min: 0.0, max: 1.0,
		amFreq: 1.0, amWave: 0.0, amDepth: 0.0,
	);
	colors = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1)];
	previewViews = Array.newClear(~numLEDs);

	sliders = Array.fill(~numLEDs, { Array.fill(allParams.size, { Array.newClear(3) }) });
	numberBoxes = Array.fill(~numLEDs, { Array.fill(allParams.size, { Array.newClear(3) }) });
	brightSliders = Array.newClear(~numLEDs);
	brightBoxes = Array.newClear(~numLEDs);
	muteButtons = Array.newClear(~numLEDs);

	presetsPath = basePath +/+ "presets/led_presets.scd";
	~bb86 = ();

	~bb86[\saveDictToFile] = { |dict, path|
		var file = File(path, "w");
		file.write(dict.asCompileString);
		file.close;
	};
	~bb86[\loadDictFromFile] = { |path|
		if(File.exists(path), {
			File.readAllString(path).interpret ? Dictionary.new;
		}, {
			Dictionary.new;
		});
	};
	~bb86[\getCurrentState] = {
		var state = Dictionary.new;
		~numLEDs.do { |led|
			allParams.do { |group, gi|
				3.do { |ci|
					state[("led" ++ led ++ "_" ++ group ++ channelLabels[ci]).asSymbol] = numberBoxes[led][gi][ci].value;
				};
			};
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
			allParams.do { |group, gi|
				var spec = paramSpecs[group];
				3.do { |ci|
					var key = (group ++ channelLabels[ci]).asSymbol;
					var val = state[("led" ++ led ++ "_" ++ group ++ channelLabels[ci]).asSymbol];
					if(val.notNil, {
						sliders[led][gi][ci].value = spec.unmap(val);
						numberBoxes[led][gi][ci].value = val;
						~lfo[led].set(key, val);
					});
				};
			};
			{ var bval = state[("led" ++ led ++ "_brightness").asSymbol];
				if(bval.notNil, {
					brightSliders[led].value = bval;
					brightBoxes[led].value = bval;
					~lfo[led].set(\brightness, bval);
				});
			}.value;
		};
		if(state[\gamma].notNil, { ~bb86[\gammaBox].valueAction_(state[\gamma]) });
		if(state[\rateMultiplier].notNil, { ~bb86[\rateMulBox].valueAction_(state[\rateMultiplier]) });
		if(state[\minRate].notNil, { ~bb86[\minRateBox].valueAction_(state[\minRate]) });
		if(state[\maxRate].notNil, { ~bb86[\maxRateBox].valueAction_(state[\maxRate]) });
	};
	~bb86[\updatePresetMenu] = {
		presetPopup.items = ["(select preset)"] ++ presets.keys.asArray.sort;
		presetPopup.value = 0;
	};

	presets = ~bb86[\loadDictFromFile].(presetsPath);

	// ========== BUILD WINDOW ==========
	~bb86[\win] = Window("86BB LED Test", Rect(50, 50, 1300, 820)).front;
	canvas = View();
	mainLayout = VLayout().margins_(4).spacing_(2);
	canvas.layout = mainLayout;

	// --- Preset bar ---
	presetPopup = PopUpMenu().items_(["(select preset)"] ++ presets.keys.asArray.sort).fixedWidth_(180);
	presetPopup.action = { |v|
		if(v.value > 0, {
			var name = v.items[v.value];
			var preset = presets[name];
			if(preset.notNil, {
				~bb86[\applyPreset].(preset);
				("Loaded preset:" + name).postln;
			});
		});
	};
	presetNameField = TextField().string_("preset1").fixedWidth_(120);

	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("Preset:").fixedWidth_(45),
		presetPopup, presetNameField,
		Button().states_([["+", Color.white, Color(0.2, 0.4, 0.8)]]).fixedWidth_(28).action_({
			var name = presetNameField.string;
			if(name.size > 0, {
				presets[name] = ~bb86[\getCurrentState].value;
				~bb86[\updatePresetMenu].value;
				~bb86[\saveDictToFile].(presets, presetsPath);
				("Saved preset:" + name).postln;
			});
		}),
		Button().states_([["-", Color.white, Color(0.8, 0.25, 0.25)]]).fixedWidth_(28).action_({
			var idx = presetPopup.value;
			if(idx > 0, {
				var name = presetPopup.items[idx];
				presets.removeAt(name);
				~bb86[\updatePresetMenu].value;
				~bb86[\saveDictToFile].(presets, presetsPath);
				("Deleted preset:" + name).postln;
			});
		}),
		nil
	).margins_(2).spacing_(4)));

	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- Preview row ---
	{ var items = List.new;
		var toggleBtn;
		toggleBtn = Button().states_([
			["Preview ON", Color.white, Color(0.3, 0.5, 0.3)],
			["Preview OFF", Color.white, Color.gray(0.35)]
		]).fixedWidth_(70);
		toggleBtn.action = { |b|
			previewActive = (b.value == 0);
			if(previewActive == false, {
				~numLEDs.do { |i| previewViews[i].background = Color.gray(0.15) };
			});
		};
		previewActive = true;
		items.add(toggleBtn);
		~numLEDs.do { |i|
			var pv = View().background_(Color.gray(0.15));
			previewViews[i] = pv;
			items.add(pv);
		};
		mainLayout.add(View().fixedHeight_(40).layout_(HLayout(*items).margins_(0).spacing_(4)));
	}.value;

	// --- LED column header ---
	{ var items = List.new;
		items.add(StaticText().string_("").fixedWidth_(70));
		~numLEDs.do { |i| items.add(StaticText().string_("LED" + (i+1)).align_(\center)) };
		mainLayout.add(View().fixedHeight_(18).layout_(HLayout(*items).margins_(0).spacing_(4)));
	}.value;

	// --- Helper: add a section of param rows ---
	~bb86[\addParamSection] = { |label, paramList, startIndex|
		mainLayout.add(View().fixedHeight_(18).layout_(HLayout(
			StaticText().string_(label).stringColor_(Color.gray(0.7)),
			nil
		).margins_(0).spacing_(4)));

		paramList.do { |group, localGi|
			var gi = startIndex + localGi;
			var spec = paramSpecs[group];
			var defVal = defaults[group];
			var groupLabel = group.asString.toUpper;

			mainLayout.add(View().fixedHeight_(16).layout_(HLayout(
				StaticText().string_(groupLabel).fixedWidth_(70),
				nil
			).margins_(0).spacing_(4)));

			3.do { |ci|
				var rowItems = List.new;
				var key = (group ++ channelLabels[ci]).asSymbol;
				rowItems.add(View().fixedWidth_(70).background_(colors[ci].alpha_(0.35)));

				~numLEDs.do { |led|
					var slider, numBox;
					slider = Slider().orientation_(\horizontal).value_(spec.unmap(defVal));
					slider.background_(colors[ci].alpha_(0.3));
					numBox = NumberBox().fixedWidth_(40).decimals_(3).value_(defVal);
					slider.action = { |sl|
						var val = spec.map(sl.value);
						numBox.value = val;
						~lfo[led].set(key, val);
					};
					numBox.action = { |nb|
						var val = nb.value.clip(spec.minval, spec.maxval);
						slider.value = spec.unmap(val);
						~lfo[led].set(key, val);
					};
					sliders[led][gi][ci] = slider;
					numberBoxes[led][gi][ci] = numBox;
					rowItems.add(slider);
					rowItems.add(numBox);
				};

				mainLayout.add(View().fixedHeight_(22).layout_(
					HLayout(*rowItems).margins_(0).spacing_(4)
				));
			};
		};
	};

	~bb86[\addParamSection].("--- Base LFO ---", baseParams, 0);
	~bb86[\addParamSection].("--- AM LFO ---", amParams, baseParams.size);

	// --- Per-LED controls: Brightness + Mute ---
	mainLayout.add(View().fixedHeight_(18).layout_(HLayout(
		StaticText().string_("--- Per LED ---").stringColor_(Color.gray(0.7)),
		nil
	).margins_(0).spacing_(4)));

	mainLayout.add(View().fixedHeight_(16).layout_(HLayout(
		StaticText().string_("BRIGHT").fixedWidth_(70), nil
	).margins_(0).spacing_(4)));

	{ var rowItems = List.new;
		rowItems.add(StaticText().string_("").fixedWidth_(70));
		~numLEDs.do { |led|
			var bSlider, bBox;
			bSlider = Slider().orientation_(\horizontal).value_(1.0);
			bBox = NumberBox().fixedWidth_(40).decimals_(2).value_(1.0);
			bSlider.action = { |sl| bBox.value = sl.value; ~lfo[led].set(\brightness, sl.value) };
			bBox.action = { |nb| var v = nb.value.clip(0,1); bSlider.value = v; ~lfo[led].set(\brightness, v) };
			brightSliders[led] = bSlider;
			brightBoxes[led] = bBox;
			rowItems.add(bSlider);
			rowItems.add(bBox);
		};
		mainLayout.add(View().fixedHeight_(22).layout_(HLayout(*rowItems).margins_(0).spacing_(4)));
	}.value;

	{ var rowItems = List.new;
		rowItems.add(StaticText().string_("MUTE").fixedWidth_(70));
		~numLEDs.do { |led|
			var btn = Button().states_([
				["M", Color.white, Color.gray(0.4)],
				["M", Color.white, Color(0.8, 0.2, 0.2)]
			]).fixedWidth_(30);
			btn.action = { |b| ~lfo[led].set(\mute, b.value) };
			muteButtons[led] = btn;
			rowItems.add(btn);
			rowItems.add(nil);
		};
		mainLayout.add(View().fixedHeight_(26).layout_(HLayout(*rowItems).margins_(0).spacing_(4)));
	}.value;

	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- Global controls ---
	[\gamma, \lagTime, \rateMult, \minRate, \maxRate].do { |which|
		var labelStr, spec, defVal, setter, slider, numBox;
		switch(which,
			\gamma, {
				labelStr = "Gamma"; spec = [0.5, 3.0, \lin, 0, 1.8].asSpec; defVal = 1.8;
				setter = { |val| ~collector.set(\gamma, val) };
			},
			\lagTime, {
				labelStr = "Lag Time"; spec = [0.0, 5.0, \lin, 0, 2.0].asSpec; defVal = 2.0;
				setter = { |val| ~lfo.do { |sy| sy.set(\lagTime, val) } };
			},
			\rateMult, {
				labelStr = "Rate Mult"; spec = [1, 10, \lin, 0.1, 5].asSpec; defVal = 5;
				setter = { |val| ~collector.set(\rateMultiplier, val) };
			},
			\minRate, {
				labelStr = "Min Rate"; spec = [1, 30, \lin, 0.5, 5].asSpec; defVal = 5;
				setter = { |val| ~collector.set(\minRate, val) };
			},
			\maxRate, {
				labelStr = "Max Rate"; spec = [5, 60, \lin, 0.5, 30].asSpec; defVal = 30;
				setter = { |val| ~collector.set(\maxRate, val) };
			}
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

		mainLayout.add(View().fixedHeight_(24).layout_(HLayout(
			StaticText().string_(labelStr).fixedWidth_(70), slider, numBox
		).margins_(0).spacing_(4)));
	};

	// --- Action buttons ---
	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["All Off", Color.white, Color(0.6, 0.2, 0.2)]]).action_({
			~numLEDs.do { |led|
				~lfo[led].set(\brightness, 0);
				brightSliders[led].value = 0;
				brightBoxes[led].value = 0;
			};
			try { ~espAddr.sendMsg("/all", *0.dup(~numLEDs * 3)) };
		}),
		Button().states_([["Reset Defaults", Color.white, Color(0.3, 0.45, 0.65)]]).action_({
			~numLEDs.do { |led|
				allParams.do { |group, gi|
					var spec = paramSpecs[group];
					var defVal = defaults[group];
					3.do { |ci|
						sliders[led][gi][ci].value = spec.unmap(defVal);
						numberBoxes[led][gi][ci].value = defVal;
						~lfo[led].set((group ++ channelLabels[ci]).asSymbol, defVal);
					};
				};
				brightSliders[led].value = 1.0;
				brightBoxes[led].value = 1.0;
				~lfo[led].set(\brightness, 1.0);
				if(muteButtons[led].value != 0, {
					muteButtons[led].value = 0;
					~lfo[led].set(\mute, 0);
				});
			};
			~bb86[\gammaBox].valueAction_(1.8);
			~bb86[\rateMulBox].valueAction_(5);
			~bb86[\minRateBox].valueAction_(5);
			~bb86[\maxRateBox].valueAction_(30);
		}),
		nil
	).margins_(2).spacing_(4)));

	mainLayout.add(nil);

	scrollView = ScrollView(~bb86[\win], ~bb86[\win].view.bounds).canvas_(canvas);
	scrollView.resize = 5;
	~bb86[\win].view.onResize_({ |view| scrollView.bounds = view.bounds });

	~bb86[\win].onClose_({
		previewActive = false;
		OSCdef(\ledForward).free;
		~lfo.do(_.free);
		~collector.free;
		~lfoGroup.free;
		~collectorGroup.free;
		~ledBus.free;
		~freqBus.free;
		~wtBufs.do(_.free);
		try { ~espAddr.sendMsg("/all", *0.dup(~numLEDs * 3)) };
		"[86BB] Closed.".postln;
	});

	"[86BB] GUI ready.".postln;
});
)
