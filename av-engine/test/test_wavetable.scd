// =====================================================
// Wavetable Morph Sanity Test
// Boot the server first (Cmd+B), then evaluate blocks.
// =====================================================

// --- 1. Allocate and fill wavetable buffers ---
(
s.waitForBoot({
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
)


// --- 2. One-shot morph: sine -> triangle -> saw -> square over 12 seconds ---
(
{
	var morph = Line.kr(0, 1, 12, doneAction: 2);
	var sig = VOsc.ar(~testWTStart + (morph * 3), 200);
	sig = sig * 0.25;
	sig ! 2;
}.play;
"Playing: sine -> triangle -> saw -> square over 12 seconds...".postln;
)


// --- 3. Continuous looping morph (stop with Cmd+.) ---
(
{
	var morph = SinOsc.kr(0.1, 3pi/2).range(0, 1);
	var sig = VOsc.ar(~testWTStart + (morph * 3), 200);
	sig = sig * 0.25;
	sig ! 2;
}.play;
"Playing: continuous looping morph (Cmd+. to stop)".postln;
)


// --- 4. Step through each waveform individually ---
x = { VOsc.ar(~testWTStart + 0, 200) * 0.25 ! 2 }.play; // sine
x.free;

x = { VOsc.ar(~testWTStart + 1, 200) * 0.25 ! 2 }.play; // triangle
x.free;

x = { VOsc.ar(~testWTStart + 2, 200) * 0.25 ! 2 }.play; // saw
x.free;

x = { VOsc.ar(~testWTStart + 3, 200) * 0.25 ! 2 }.play; // square (uses guard buf, safe)
x.free;


// --- 5. Cleanup ---
(
~testWT.do(_.free);
~testWT = nil;
~testWTStart = nil;
"Test wavetable buffers freed.".postln;
)
