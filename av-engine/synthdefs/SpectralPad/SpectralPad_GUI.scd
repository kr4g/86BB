(
var win, node, sampleBuf;
var paramViews = IdentityDictionary.new;
var presets = Dictionary.new;
var presetPopup, presetNameField;
var makeSlider, getCurrentParams, setParams, updatePresetMenu;
var savePresetsToFile, loadPresetsFromFile;
var presetsPath, synthDefPath, samplePath;
var fluxableParams;

presetsPath = thisProcess.nowExecutingPath.dirname +/+ "SpectralPad_presets.scd";
synthDefPath = thisProcess.nowExecutingPath.dirname +/+ "SpectralPad_SynthDef.scd";
samplePath = thisProcess.nowExecutingPath.dirname +/+ "../../samples/gut_recording.wav";

fluxableParams = [\rate, \rq, \bandAmRate, \scramble, \freezeThresh,
	\grainRate, \grainDur, \padAmRate, \padMaskRate, \dryWet, \grainPadMix];

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
	thisProcess.interpreter.executeFile(synthDefPath);

	sampleBuf = Buffer.read(s, samplePath);
	s.sync;
	("Sample loaded:" + samplePath + "(bufnum" + sampleBuf.bufnum ++ ")").postln;

	loadPresetsFromFile.value;

	win = Window("SpectralPad", Rect(100, 50, 720, 920)).front;

	ScrollView(win, win.view.bounds)
	.canvas_(View().layout_(VLayout(

		View().layout_(HLayout(
			Button().states_([
				["PLAY", Color.white, Color.green(0.6)],
				["STOP", Color.white, Color.red(0.6)]
			]).fixedWidth_(100).action_({ |btn|
				if(btn.value == 1) {
					var currentParams = getCurrentParams.value;
					node = Synth(\spectralPad, [\bufnum, sampleBuf.bufnum]);
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
					~spectralPadNode = node;
					"SpectralPad started".postln;
				} {
					if(node.notNil) { node.set(\gate, 0); node = nil };
					"SpectralPad stopped".postln;
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

		StaticText().string_("SOURCE").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "rate (semi)", \rate, 0,
			ControlSpec(-24, 36, \lin, 0.1, 0)),
		makeSlider.(win.view, "flux", \sourceFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \sourceFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("FILTER BANK").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "freq lo (Hz)", \freqLo, 50,
			ControlSpec(20, 500, \exp, 0, 50)),
		makeSlider.(win.view, "freq hi (Hz)", \freqHi, 9000,
			ControlSpec(1000, 16000, \exp, 0, 9000)),
		makeSlider.(win.view, "rq", \rq, 1.0,
			ControlSpec(0.01, 1.0, \exp, 0, 1.0)),
		makeSlider.(win.view, "AM rate", \bandAmRate, 0.075,
			ControlSpec(0.01, 1.0, \exp, 0, 0.075)),
		makeSlider.(win.view, "flux", \filterFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \filterFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("SPECTRAL").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "scramble", \scramble, 0.75,
			ControlSpec(0, 1, \lin, 0.01, 0.75)),
		makeSlider.(win.view, "freeze", \freezeThresh, 0.3,
			ControlSpec(0, 1, \lin, 0.01, 0.3)),
		makeSlider.(win.view, "flux", \spectralFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \spectralFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("GRAIN").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "rate", \grainRate, 1.0,
			ControlSpec(0.005, 20, \exp, 0, 1.0)),
		makeSlider.(win.view, "duration", \grainDur, 0.005,
			ControlSpec(0.001, 0.1, \exp, 0, 0.005)),
		makeSlider.(win.view, "flux", \grainFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \grainFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("PAD BPF").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "AM rate", \padAmRate, 5.0,
			ControlSpec(0.1, 100, \exp, 0, 5.0)),
		makeSlider.(win.view, "mask rate", \padMaskRate, 0.025,
			ControlSpec(0.005, 0.5, \exp, 0, 0.025)),
		makeSlider.(win.view, "flux", \padFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \padFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("MIX").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "dry / wet", \dryWet, 0.75,
			ControlSpec(-1, 1, \lin, 0.01, 0.75)),
		makeSlider.(win.view, "grain / pad", \grainPadMix, 0.75,
			ControlSpec(-1, 1, \lin, 0.01, 0.75)),
		makeSlider.(win.view, "flux", \mixFlux, 0.15,
			ControlSpec(0, 1, \lin, 0.01, 0.15)),
		makeSlider.(win.view, "flux rate", \mixFluxRate, 0.1,
			ControlSpec(0.01, 5, \exp, 0, 0.1)),

		StaticText().string_("GLOBAL").font_(Font.default.bold_(true)),
		makeSlider.(win.view, "gain (dB)", \gain, 0,
			ControlSpec(-24, 12, \lin, 0.1, 0)),
		makeSlider.(win.view, "lagTime", \lagTime, 2,
			ControlSpec(0.1, 30, \exp, 0, 2)),

		nil
	).margins_(10).spacing_(3)));

	win.onClose_({
		if(node.notNil) { node.free };
		if(sampleBuf.notNil) { sampleBuf.free };
	});

	if(presets["default"].notNil) {
		setParams.value(presets["default"]);
		"Loaded 'default' preset on startup".postln;
	};

	"SpectralPad GUI ready".postln;
});
)
