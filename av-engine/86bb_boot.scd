ServerOptions.devices;

(
Server.killAll;
Buffer.freeAll;
s = Server.local;

~nChans = 4;
~sr = 48000;

// TODO: set these to the installation hardware
s.options.outDevice_(
	// "MacBook Pro Speakers"
	"UMC404HD 192k"
);
// s.options.inDevice_("Built-in Microph");
s.options.numOutputBusChannels_(~nChans);
s.options.numInputBusChannels_(0);
s.options.sampleRate_(~sr);
s.options.memSize_(2.pow(20));
s.newBusAllocators;

s.waitForBoot({
	var basePath = thisProcess.nowExecutingPath.dirname;
	var sigSize = 1024;
	var sigs = Array.newClear(4);
	var sqSig;

	"[86BB] Server booted.".postln;

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
	(basePath +/+ "synthdefs/gut_voices.scd").load;
	s.sync;
	"[86BB] SynthDefs loaded.".postln;

	// ========== OSC RESPONDERS ==========
	(basePath +/+ "osc_responders.scd").load;
	s.sync;
	"[86BB] OSC responders loaded.".postln;

	// ========== READY ==========
	s.sync;
	"[86BB] Ready.".postln;
});
)
