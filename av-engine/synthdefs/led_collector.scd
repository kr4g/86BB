SynthDef(\ledCollector, {
	arg ledBusIndex = 0, freqBusIndex = 0,
	minRate = 5, maxRate = 30,
	rateMultiplier = 5,
	gamma = 1.8;

	var numCh = 12;
	var ledVals = In.kr(ledBusIndex, numCh);
	var freqVals = In.kr(freqBusIndex, numCh);

	var corrected = ledVals.clip(0.0, 1.0).pow(gamma);

	var maxFreq = freqVals.reduce(\max);
	var updateRate = (maxFreq * rateMultiplier).clip(minRate, maxRate);

	SendReply.kr(Impulse.kr(updateRate), '/leds', corrected);
}).add;
