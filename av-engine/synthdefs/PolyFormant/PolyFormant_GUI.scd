(
var win, node;
var paramViews = IdentityDictionary.new;
var presets = Dictionary.new;
var presetPopup, presetNameField;
var makeSlider, getCurrentParams, setParams, updatePresetMenu;
var savePresetsToFile, loadPresetsFromFile;
var presetsPath, synthDefPath;
var wtBufs, wtBufStart;
var fluxableParams;

presetsPath = thisProcess.nowExecutingPath.dirname +/+ "PolyFormant_presets.scd";
synthDefPath = thisProcess.nowExecutingPath.dirname +/+ "PolyFormant_SynthDef.scd";

fluxableParams = [\fund, \ratio, \trigRate, \envSustain, \envRange, \prob,
	\shift, \bw, \amRate, \amDepth, \amSmooth, \amShape, \sampleRate, \bitDepth];

savePresetsToFile = {
	var file = File(presetsPath, "w");
	file.write(presets.asCompileString);
	file.close;
	("Presets saved to:" + presetsPath).postln;
};

loadPresetsFromFile = {
	if(File.exists(presetsPath)) {
		var str = File.readAllString(presetsPath);
		presets = str.interpret ? Dictionary.new;
		("Presets loaded from:" + presetsPath).postln;
	} {
		presets = Dictionary.new;
		"No preset file found, starting fresh".postln;
	};
};

getCurrentParams = {
	var params = Dictionary.new;
	var excludeKeys = [\lagTime];
	paramViews.keysValuesDo { |param, view|
		if(excludeKeys.includes(param).not) {
			params[param] = view[1].value;
			params[(param ++ "_min").asSymbol] = view[3].value;
			params[(param ++ "_max").asSymbol] = view[4].value;
		};
	};
	params;
};

setParams = { |params|
	var skipKeys = Set[\lagTime, \lagTime_min, \lagTime_max];
	params.keysValuesDo { |param, value|
		var base = param.asString;
		var view;
		if(skipKeys.includes(param).not) {
			if(base.endsWith("_min")) {
				view = paramViews[base.replace("_min", "").asSymbol];
				if(view.notNil) {
					view[3].value = value;
					view[3].doAction;
				};
			} {
				if(base.endsWith("_max")) {
					view = paramViews[base.replace("_max", "").asSymbol];
					if(view.notNil) {
						view[4].value = value;
						view[4].doAction;
					};
				} {
					view = paramViews[param];
					if(view.notNil) {
						view[1].value = value;
						view[0].value = view[2].unmap(value);
					};
				};
			};
		};
	};
};

updatePresetMenu = {
	var items = ["(select preset)"] ++ presets.keys.asArray.sort;
	presetPopup.items = items;
	presetPopup.value = 0;
};

makeSlider = { |parent, label, param, default, spec|
	var row, lbl, minBox, maxBox, slider, valBox;
	var currentSpec = spec;
	var minArgName = (param ++ "Min").asSymbol;
	var maxArgName = (param ++ "Max").asSymbol;
	var isFluxable = fluxableParams.includes(param);

	row = View(parent, Rect(0, 0, 660, 25)).layout_(HLayout(
		lbl = StaticText().string_(label).fixedWidth_(110),
		minBox = NumberBox().value_(spec.minval).fixedWidth_(50).action_({ |v|
			currentSpec = ControlSpec(v.value, maxBox.value, spec.warp, spec.step, default);
			paramViews[param][2] = currentSpec;
			slider.value = currentSpec.unmap(valBox.value);
			if(isFluxable) {
				if(node.notNil) { node.set(minArgName, v.value) };
			};
		}),
		maxBox = NumberBox().value_(spec.maxval).fixedWidth_(50).action_({ |v|
			currentSpec = ControlSpec(minBox.value, v.value, spec.warp, spec.step, default);
			paramViews[param][2] = currentSpec;
			slider.value = currentSpec.unmap(valBox.value);
			if(isFluxable) {
				if(node.notNil) { node.set(maxArgName, v.value) };
			};
		}),
		slider = Slider().orientation_(\horizontal).value_(spec.unmap(default)).action_({ |v|
			var val = currentSpec.map(v.value);
			valBox.value = val;
			if(node.notNil) { node.set(param, val) };
		}),
		valBox = NumberBox().value_(default).fixedWidth_(60).action_({ |v|
			slider.value = currentSpec.unmap(v.value);
			if(node.notNil) { node.set(param, v.value) };
		})
	).margins_(2).spacing_(4));

	paramViews[param] = [slider, valBox, currentSpec, minBox, maxBox];
	row;
};

s.waitForBoot({
	var sigSize = 1024;
	var sigs = Array.newClear(4);

	thisProcess.interpreter.executeFile(synthDefPath);

	wtBufs = Buffer.allocConsecutive(5, s, sigSize * 2);
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

	4.do { |i| wtBufs[i].loadCollection(sigs[i].asWavetable) };
	wtBufs[4].loadCollection(sigs[3].asWavetable);
	s.sync;

	wtBufStart = wtBufs[0].bufnum;
	("Wavetable buffers ready (bufs" + wtBufStart + "-" + (wtBufStart + 3) ++ ", guard at" + (wtBufStart + 4) ++ ")").postln;

	loadPresetsFromFile.value;

	win = Window("PolyFormant", Rect(100, 50, 720, 1020)).front;

	ScrollView(win, win.view.bounds)
	.canvas_(View().layout_(VLayout(

		View().layout_(HLayout(
			Button().states_([
				["PLAY", Color.white, Color.green(0.6)],
				["STOP", Color.white, Color.red(0.6)]
			]).fixedWidth_(100).action_({ |btn|
				if(btn.value == 1) {
					var currentParams = getCurrentParams.value;
					node = Synth(\polyFormant, [\wtBufStart, wtBufStart]);
					currentParams.keysValuesDo { |param, value|
						var base = param.asString;
						if(base.endsWith("_min")) {
							var synthArg = (base.replace("_min", "") ++ "Min").asSymbol;
							node.set(synthArg, value);
						} {
							if(base.endsWith("_max")) {
								var synthArg = (base.replace("_max", "") ++ "Max").asSymbol;
								node.set(synthArg, value);
							} {
								node.set(param, value);
							};
						};
					};
					node.set(\lagTime, paramViews[\lagTime][1].value);
					~polyFormantNode = node;
					"PolyFormant started".postln;
				} {
					if(node.notNil) { node.set(\gate, 0); node = nil };
					"PolyFormant stopped".postln;
				};
			}),
			Button().states_([["FREE ALL", Color.white, Color.gray(0.5)]]).fixedWidth_(100).action_({
				s.freeAll;
				node = nil;
			})
		)),

		View().layout_(HLayout(
			presetPopup = PopUpMenu().items_(["(select preset)"] ++ presets.keys.asArray.sort).fixedWidth_(200).action_({ |v|
				if(v.value > 0) {
					var name = v.items[v.value];
					var params = presets[name];
					if(params.notNil) {
						setParams.value(params);
						if(node.notNil) {
							var skipKeys = Set[\lagTime, \lagTime_min, \lagTime_max];
							params.keysValuesDo { |param, value|
								var base = param.asString;
								if(skipKeys.includes(param).not) {
									if(base.endsWith("_min")) {
										var synthArg = (base.replace("_min", "") ++ "Min").asSymbol;
										node.set(synthArg, value);
									} {
										if(base.endsWith("_max")) {
											var synthArg = (base.replace("_max", "") ++ "Max").asSymbol;
											node.set(synthArg, value);
										} {
											node.set(param, value);
										};
									};
								};
							};
							node.set(\lagTime, paramViews[\lagTime][1].value);
						};
						("Loaded preset:" + name).postln;
					};
				};
			}),
			presetNameField = TextField().string_("preset1").fixedWidth_(140),
			Button().states_([["+", Color.white, Color.blue(0.6)]]).fixedWidth_(40).action_({
				var name = presetNameField.string;
				if(name.size > 0) {
					presets[name] = getCurrentParams.value;
					updatePresetMenu.value;
					savePresetsToFile.value;
					("Saved preset:" + name).postln;
				};
			}),
			Button().states_([["-", Color.white, Color.red(0.6)]]).fixedWidth_(40).action_({
				var idx = presetPopup.value;
				if(idx > 0) {
					var name = presetPopup.items[idx];
					presets.removeAt(name);
					updatePresetMenu.value;
					savePresetsToFile.value;
					("Deleted preset:" + name).postln;
				};
			})
		)),

		StaticText().string_("PITCH").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "fund (MIDI)", \fund, 43,
			ControlSpec(24, 84, \lin, 0.1, 43)),
		makeSlider.(win.view, "fund LFO rate", \fundLFORate, 0,
			ControlSpec(0, 10, \lin, 0.001, 0)),
		makeSlider.(win.view, "fund LFO shape", \fundLFOShape, 0,
			ControlSpec(0, 1, \lin, 0.01, 0)),
		makeSlider.(win.view, "fund LFO smooth", \fundLFOSmooth, 0.1,
			ControlSpec(0, 0.5, \lin, 0.001, 0.1)),
		makeSlider.(win.view, "ratio", \ratio, 1.0,
			ControlSpec(0.5, 2.0, \lin, 0.01, 1.0)),
		makeSlider.(win.view, "flux", \pitchFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \pitchFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("TRIGGER / ENVELOPE").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "trigRate", \trigRate, 5.0,
			ControlSpec(0.1, 51, \exp, 0, 5.0)),
		makeSlider.(win.view, "envSustain", \envSustain, 8.0,
			ControlSpec(0.125, 64, \exp, 0, 8.0)),
		makeSlider.(win.view, "envRange", \envRange, 0.5,
			ControlSpec(0, 1, \lin, 0.01, 0.5)),
		makeSlider.(win.view, "prob", \prob, 1.0,
			ControlSpec(0, 1, \lin, 0.01, 1.0)),
		makeSlider.(win.view, "flux", \trigFlux, 0.2,
			ControlSpec(0, 1, \lin, 0.01, 0.2)),
		makeSlider.(win.view, "flux rate", \trigFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("FORMANT").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "shift (Hz)", \shift, 10,
			ControlSpec(-15, 55, \lin, 0.1, 10)),
		makeSlider.(win.view, "bw (Hz)", \bw, 110,
			ControlSpec(55, 440, \exp, 0, 110)),
		makeSlider.(win.view, "flux", \formantFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \formantFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("AM").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "rate", \amRate, 0.5,
			ControlSpec(0.01, 5, \exp, 0, 0.5)),
		makeSlider.(win.view, "depth", \amDepth, 0.7,
			ControlSpec(0, 1, \lin, 0.01, 0.7)),
		makeSlider.(win.view, "smooth", \amSmooth, 0.05,
			ControlSpec(0, 0.5, \lin, 0.001, 0.05)),
		makeSlider.(win.view, "shape", \amShape, 0.0,
			ControlSpec(0, 1, \lin, 0.01, 0.0)),
		makeSlider.(win.view, "flux", \amFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \amFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("BIT CRUSH").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "sampleRate", \sampleRate, 48000,
			ControlSpec(12000, 48000, \exp, 0, 48000)),
		makeSlider.(win.view, "bitDepth", \bitDepth, 24,
			ControlSpec(12, 24, \lin, 1, 24)),
		makeSlider.(win.view, "flux", \decimFlux, 0.0,
			ControlSpec(0, 1, \lin, 0.01, 0.0)),
		makeSlider.(win.view, "flux rate", \decimFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("GLOBAL").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "gain (dB)", \gain, 18,
			ControlSpec(-12, 24, \lin, 0.1, 18)),
		makeSlider.(win.view, "lagTime", \lagTime, 2,
			ControlSpec(0.1, 30, \exp, 0, 2)),

		StaticText().string_("VOICE LEVELS (" ++ ~nVox ++ " voices)").font_(Font.default.bold_(true)),
		*~nVox.collect({ |i|
			var param = ("vox" ++ (i+1) ++ "amp").asSymbol;
			makeSlider.(win.view, "vox " ++ (i+1), param, 1.0,
				ControlSpec(0, 1, \lin, 0.01, 1.0));
		}) ++ [nil]
	).margins_(10).spacing_(3)));

	win.onClose_({
		if(node.notNil) { node.free };
		wtBufs.do(_.free);
	});

	if(presets["default"].notNil) {
		setParams.value(presets["default"]);
		"Loaded 'default' preset on startup".postln;
	};

	"PolyFormant GUI ready".postln;
});
)
