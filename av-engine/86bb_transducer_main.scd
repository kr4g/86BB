// =====================================================
// 86 Billion Butterflies — Transducer Preset Designer
// Evaluate this block to boot + open GUI.
// Design presets for \drips, \purrs, \burps synths.
// =====================================================
(
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
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;
	var canvas, mainLayout, scrollView;
	var presetsPath, presets, presetPopup, presetNameField;
	var sliders, boxes, muteButtons;

	~bb86t = ();
	~nTransducerDims = 43;

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
	(basePath +/+ "synthdefs/transducers.scd").load;
	s.sync;

	// ========== SYNTH INSTANCES ==========
	~drips = Synth(\drips, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~purrs = Synth(\purrs, [\out, 0, \wtBufStart, ~wtBufStart, \gain, -96]);
	~burps = Synth(\burps, [\out, 0, \gain, -96]);
	s.sync;

	// ========== PARAMETER DEFINITIONS ==========
	// Packing order: drips(16), purrs(19), burps(8) = 43 total
	// Each entry: [synthName, paramSymbol]
	// Grouped for GUI display; flattened for array packing.

	~bb86t[\synthDefs] = [
		[\drips, [
			[[\prob1, \prob2], "Probability"],
			[[\wtPos1, \wtPos2], "AM Wavetable"],
			[[\amRate1, \amRate2], "AM Rate"],
			[[\amMul1, \amMul2], "AM Depth"],
			[[\freqWtPos1, \freqWtPos2], "Freq Wavetable"],
			[[\freqRate1, \freqRate2], "Freq Rate"],
			[[\sweepLo], "Sweep Lo"],
			[[\sweepHi], "Sweep Hi"],
			[[\hpFreq], "HP Freq"],
			[[\gain], "Gain"],
		]],
		[\purrs, [
			[[\freqMin1, \freqMin2], "Freq Min"],
			[[\freqMax1, \freqMax2], "Freq Max"],
			[[\freqWtPos1, \freqWtPos2], "Freq Wavetable"],
			[[\freqRate1, \freqRate2], "Freq Rate"],
			[[\width1, \width2], "Pulse Width"],
			[[\wtPos1, \wtPos2], "AM Wavetable"],
			[[\amRate1, \amRate2], "AM Rate"],
			[[\amMul1, \amMul2], "AM Depth"],
			[[\lpFreq1, \lpFreq2], "LP Freq"],
			[[\gain], "Gain"],
		]],
		[\burps, [
			[[\trigRate1, \trigRate2], "Trig Rate"],
			[[\fund], "Fundamental"],
			[[\sweepHiMin], "Sweep Hi Min"],
			[[\sweepHiMax], "Sweep Hi Max"],
			[[\formantBW], "Formant BW"],
			[[\combMix], "Comb Mix"],
			[[\gain], "Gain"],
		]],
	];

	~bb86t[\dripsFlat] = [\prob1, \prob2, \wtPos1, \wtPos2, \amRate1, \amRate2, \amMul1, \amMul2,
		\freqWtPos1, \freqWtPos2, \freqRate1, \freqRate2, \sweepLo, \sweepHi, \hpFreq, \gain];
	~bb86t[\purrsFlat] = [\freqMin1, \freqMin2, \freqMax1, \freqMax2, \freqWtPos1, \freqWtPos2,
		\freqRate1, \freqRate2, \width1, \width2, \wtPos1, \wtPos2,
		\amRate1, \amRate2, \amMul1, \amMul2, \lpFreq1, \lpFreq2, \gain];
	~bb86t[\burpsFlat] = [\trigRate1, \trigRate2, \fund, \sweepHiMin, \sweepHiMax, \formantBW, \combMix, \gain];

	~bb86t[\paramSpecs] = (
		drips_prob1: [0.0, 1.0, \lin, 0, 0.66].asSpec,
		drips_prob2: [0.0, 1.0, \lin, 0, 0.66].asSpec,
		drips_wtPos1: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		drips_wtPos2: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		drips_amRate1: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		drips_amRate2: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		drips_amMul1: [0.0, 1.0, \lin, 0, 0.75].asSpec,
		drips_amMul2: [0.0, 1.0, \lin, 0, 0.75].asSpec,
		drips_freqWtPos1: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		drips_freqWtPos2: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		drips_freqRate1: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		drips_freqRate2: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		drips_sweepLo: [20, 5000, \exp, 0, 20].asSpec,
		drips_sweepHi: [100, 20000, \exp, 0, 20000].asSpec,
		drips_hpFreq: [20, 10000, \exp, 0, 2500].asSpec,
		drips_gain: [-96, 6, \lin, 0, -24].asSpec,

		purrs_freqMin1: [0.5, 30, \exp, 0, 3].asSpec,
		purrs_freqMin2: [0.5, 30, \exp, 0, 3].asSpec,
		purrs_freqMax1: [1, 120, \exp, 0, 31].asSpec,
		purrs_freqMax2: [1, 120, \exp, 0, 31].asSpec,
		purrs_freqWtPos1: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		purrs_freqWtPos2: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		purrs_freqRate1: [0.001, 5.0, \exp, 0, 0.05].asSpec,
		purrs_freqRate2: [0.001, 5.0, \exp, 0, 0.05].asSpec,
		purrs_width1: [0.0, 1.0, \lin, 0, 0.5].asSpec,
		purrs_width2: [0.0, 1.0, \lin, 0, 0.5].asSpec,
		purrs_wtPos1: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		purrs_wtPos2: [0.0, 1.0, \lin, 0, 0.0].asSpec,
		purrs_amRate1: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		purrs_amRate2: [0.01, 10.0, \exp, 0, 0.1].asSpec,
		purrs_amMul1: [0.0, 1.0, \lin, 0, 0.75].asSpec,
		purrs_amMul2: [0.0, 1.0, \lin, 0, 0.75].asSpec,
		purrs_lpFreq1: [20, 1000, \exp, 0, 120].asSpec,
		purrs_lpFreq2: [20, 1000, \exp, 0, 120].asSpec,
		purrs_gain: [-96, 6, \lin, 0, 0].asSpec,

		burps_trigRate1: [0.01, 3.0, \exp, 0, 0.3].asSpec,
		burps_trigRate2: [0.01, 3.0, \exp, 0, 0.3].asSpec,
		burps_fund: [1, 30, \exp, 0, 6].asSpec,
		burps_sweepHiMin: [4, 256, \exp, 0, 16].asSpec,
		burps_sweepHiMax: [8, 512, \exp, 0, 128].asSpec,
		burps_formantBW: [10, 200, \exp, 0, 55].asSpec,
		burps_combMix: [-60, 0, \lin, 0, -3].asSpec,
		burps_gain: [-96, 6, \lin, 0, 0].asSpec,
	);

	// Dictionary keyed by prefixed symbol (e.g. drips_prob1)
	sliders = Dictionary.new;
	boxes = Dictionary.new;
	muteButtons = Dictionary.new;

	// ========== STATE HELPERS ==========
	~bb86t[\getCurrentState] = {
		var state = Dictionary.new;
		~bb86t[\synthDefs].do { |entry|
			var synthName = entry[0];
			entry[1].do { |group|
				group[0].do { |param|
					var key = (synthName ++ "_" ++ param).asSymbol;
					state[key] = boxes[key].value;
				};
			};
		};
		state;
	};

	~bb86t[\applyPreset] = { |state|
		~bb86t[\synthDefs].do { |entry|
			var synthName = entry[0];
			var synthInst = switch(synthName, \drips, { ~drips }, \purrs, { ~purrs }, \burps, { ~burps });
			entry[1].do { |group|
				group[0].do { |param|
					var key = (synthName ++ "_" ++ param).asSymbol;
					var spec = ~bb86t[\paramSpecs][key];
					var val = state[key];
					if(val.notNil and: { spec.notNil }, {
						boxes[key].value = val;
						sliders[key].value = spec.unmap(val);
						if(muteButtons[synthName].value == 0, {
							synthInst.set(param, val);
						});
					});
				};
			};
		};
	};

	~bb86t[\getStateAsArray] = {
		var arr = Array.new(~nTransducerDims);
		[[\drips, ~bb86t[\dripsFlat]], [\purrs, ~bb86t[\purrsFlat]], [\burps, ~bb86t[\burpsFlat]]].do { |pair|
			var synthName = pair[0];
			pair[1].do { |param|
				arr = arr.add(boxes[(synthName ++ "_" ++ param).asSymbol].value);
			};
		};
		arr;
	};

	~bb86t[\applyStateFromArray] = { |arr|
		var idx = 0;
		[[\drips, ~bb86t[\dripsFlat], ~drips], [\purrs, ~bb86t[\purrsFlat], ~purrs], [\burps, ~bb86t[\burpsFlat], ~burps]].do { |triple|
			var synthName = triple[0];
			var params = triple[1];
			var synthInst = triple[2];
			params.do { |param|
				var key = (synthName ++ "_" ++ param).asSymbol;
				var spec = ~bb86t[\paramSpecs][key];
				var val = arr[idx];
				if(spec.notNil, {
					boxes[key].value = val;
					sliders[key].value = spec.unmap(val);
					synthInst.set(param, val);
				});
				idx = idx + 1;
			};
		};
	};

	~bb86t[\updatePresetMenu] = { presetPopup.items = ["(select preset)"] ++ presets.keys.asArray.sort; presetPopup.value = 0 };
	~bb86t[\saveDictToFile] = { |dict, path| var file = File(path, "w"); file.write(dict.asCompileString); file.close };
	~bb86t[\loadDictFromFile] = { |path| if(File.exists(path), { File.readAllString(path).interpret ? Dictionary.new }, { Dictionary.new }) };

	presetsPath = basePath +/+ "presets/transducer_presets.scd";
	presets = ~bb86t[\loadDictFromFile].(presetsPath);

	// ========== BUILD WINDOW ==========
	~bb86t[\win] = Window("86BB Transducer Presets", Rect(50, 50, 700, 850)).front;
	canvas = View();
	mainLayout = VLayout().margins_(4).spacing_(2);
	canvas.layout = mainLayout;

	// --- Preset bar ---
	presetPopup = PopUpMenu().items_(["(select preset)"] ++ presets.keys.asArray.sort).fixedWidth_(200);
	presetPopup.action = { |v|
		if(v.value > 0, {
			var name = v.items[v.value];
			if(presets[name].notNil, {
				~bb86t[\applyPreset].(presets[name]);
				("Loaded preset:" + name).postln;
			});
		});
	};
	presetNameField = TextField().string_("preset1").fixedWidth_(140);

	mainLayout.add(View().fixedHeight_(28).layout_(HLayout(
		StaticText().string_("Preset:").fixedWidth_(50),
		presetPopup, presetNameField,
		Button().states_([["+", Color.white, Color(0.2, 0.4, 0.8)]]).fixedWidth_(28).action_({
			var name = presetNameField.string;
			if(name.size > 0, {
				presets[name] = ~bb86t[\getCurrentState].value;
				~bb86t[\updatePresetMenu].value;
				~bb86t[\saveDictToFile].(presets, presetsPath);
				("Saved preset:" + name).postln;
			});
		}),
		Button().states_([["-", Color.white, Color(0.8, 0.25, 0.25)]]).fixedWidth_(28).action_({
			var idx = presetPopup.value;
			if(idx > 0, {
				presets.removeAt(presetPopup.items[idx]);
				~bb86t[\updatePresetMenu].value;
				~bb86t[\saveDictToFile].(presets, presetsPath);
			});
		}), nil
	).margins_(2).spacing_(4)));
	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));

	// --- Build sections for each synth ---
	~bb86t[\synthDefs].do { |entry|
		var synthName = entry[0];
		var groups = entry[1];
		var synthInst = switch(synthName, \drips, { ~drips }, \purrs, { ~purrs }, \burps, { ~burps });
		var color = switch(synthName,
			\drips, { Color(0.4, 0.7, 1.0) },
			\purrs, { Color(0.6, 0.9, 0.4) },
			\burps, { Color(1.0, 0.6, 0.3) }
		);
		var muteBtn;

		mainLayout.add(View().fixedHeight_(22).layout_(HLayout(
			StaticText().string_("═══ " ++ synthName.asString.toUpper ++ " ═══").stringColor_(color), nil
		).margins_(0).spacing_(4)));

		muteBtn = Button().states_([
			["Unmuted", Color.white, Color.gray(0.4)],
			["MUTED", Color.white, Color(0.8, 0.2, 0.2)]
		]).fixedWidth_(80);
		muteBtn.action = { |b|
			if(b.value == 1, {
				synthInst.set(\gain, -96);
			}, {
				var gainKey = (synthName ++ "_gain").asSymbol;
				synthInst.set(\gain, boxes[gainKey].value);
			});
		};
		muteButtons[synthName] = muteBtn;
		mainLayout.add(View().fixedHeight_(26).layout_(HLayout(muteBtn, nil).margins_(0).spacing_(4)));

		groups.do { |group|
			var paramList = group[0];
			var groupLabel = group[1];

			if(paramList.size > 1, {
				mainLayout.add(View().fixedHeight_(16).layout_(HLayout(
					StaticText().string_(groupLabel).stringColor_(Color.gray(0.65)).fixedWidth_(100), nil
				).margins_(0).spacing_(4)));
			});

			paramList.do { |param|
				var key = (synthName ++ "_" ++ param).asSymbol;
				var spec = ~bb86t[\paramSpecs][key];
				var defVal = spec.default;
				var slider, numBox;
				var label = if(paramList.size > 1, { param.asString }, { groupLabel });

				slider = Slider().orientation_(\horizontal).value_(spec.unmap(defVal));
				numBox = NumberBox().fixedWidth_(60).decimals_(3).value_(defVal);

				slider.action = { |sl|
					var val = spec.map(sl.value);
					numBox.value = val;
					if(muteButtons[synthName].value == 0, {
						synthInst.set(param, val);
					});
				};
				numBox.action = { |nb|
					var val = nb.value.clip(spec.minval, spec.maxval);
					slider.value = spec.unmap(val);
					if(muteButtons[synthName].value == 0, {
						synthInst.set(param, val);
					});
				};

				sliders[key] = slider;
				boxes[key] = numBox;

				mainLayout.add(View().fixedHeight_(22).layout_(HLayout(
					StaticText().string_(label).fixedWidth_(100),
					slider, numBox
				).margins_(0).spacing_(4)));
			};
		};

		mainLayout.add(View().fixedHeight_(4).background_(color.alpha_(0.3)));
	};

	// --- Action buttons ---
	mainLayout.add(View().fixedHeight_(2).background_(Color.gray(0.4)));
	mainLayout.add(View().fixedHeight_(30).layout_(HLayout(
		Button().states_([["All Silent", Color.white, Color(0.6, 0.2, 0.2)]]).action_({
			[\drips, \purrs, \burps].do { |sn| muteButtons[sn].valueAction_(1) };
		}),
		Button().states_([["All Unmute", Color.white, Color(0.3, 0.5, 0.3)]]).action_({
			[\drips, \purrs, \burps].do { |sn| muteButtons[sn].valueAction_(0) };
		}),
		Button().states_([["Reset Defaults", Color.white, Color(0.3, 0.45, 0.65)]]).action_({
			~bb86t[\synthDefs].do { |entry|
				var synthName = entry[0];
				var synthInst = switch(synthName, \drips, { ~drips }, \purrs, { ~purrs }, \burps, { ~burps });
				entry[1].do { |group|
					group[0].do { |param|
						var key = (synthName ++ "_" ++ param).asSymbol;
						var spec = ~bb86t[\paramSpecs][key];
						var defVal = spec.default;
						sliders[key].value = spec.unmap(defVal);
						boxes[key].value = defVal;
						synthInst.set(param, defVal);
					};
				};
				muteButtons[synthName].value = 0;
			};
		}), nil
	).margins_(2).spacing_(4)));

	mainLayout.add(nil);

	scrollView = ScrollView(~bb86t[\win], ~bb86t[\win].view.bounds).canvas_(canvas);
	scrollView.resize = 5;
	~bb86t[\win].view.onResize_({ |view| scrollView.bounds = view.bounds });

	~bb86t[\win].onClose_({
		~drips.set(\gate, 0);
		~purrs.set(\gate, 0);
		~burps.set(\gate, 0);
		~wtBufs.do(_.free);
		"[86BB Transducer] Closed.".postln;
	});

	"[86BB Transducer] GUI ready. 43 params across drips/purrs/burps.".postln;
});
)
