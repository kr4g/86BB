// OSC responders for communication between Express server and SuperCollider.
// The Express server sends OSC messages to sclang on the default port (57120).
// Add handlers here as the installation develops.

(
~oscPort = 57120;

OSCdef(\gutStateUpdate, { |msg|
	var json = msg[1].asString;
	("[86BB] Received gut-state update:" + json).postln;
	// TODO: parse JSON and map to synth parameters
}, '/86bb/gut-state');

OSCdef(\foodOrder, { |msg|
	var foodId = msg[1].asString;
	("[86BB] Food ordered:" + foodId).postln;
	// TODO: trigger a sound / visual response
}, '/86bb/food-order');

"[86BB] OSC responders registered on port %.\n".postf(~oscPort);
)
