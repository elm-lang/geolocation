Elm.Native.Geolocation = {};
Elm.Native.Geolocation.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Geolocation = localRuntime.Native.Geolocation || {};
	if (localRuntime.Native.Geolocation.values)
	{
		return localRuntime.Native.Geolocation.values;
	}

	var Maybe = Elm.Maybe.make(localRuntime);
	var Scheduler = Elm.Native.Scheduler.make(localRuntime);


	// JS values to Elm values

	function elmPosition(rawPosition)
	{
		var coords = rawPosition.coords;

		var rawAltitude = coords.altitude;
		var rawAccuracy = coords.altitudeAccuracy;
		var altitude =
			(rawAltitude === null || rawAccuracy === null)
				? Maybe.Nothing
				: Maybe.Just({ value: rawAltitude, accuracy: rawAccuracy });

		var heading = coords.heading;
		var speed = coords.speed;
		var movement =
			(heading === null || speed === null)
				? Maybe.Nothing
				: Maybe.Just(
					speed === 0
						? { ctor: 'Static' }
						: { ctor: 'Moving', _0: { speed: speed, degreesFromNorth: heading } }
				);

		return {
			latitude: coords.latitude,
			longitude: coords.longitude,
			accuracy: coords.accuracy,
			altitude: altitude,
			movement: movement,
			timestamp: rawPosition.timestamp
		};
	}

	var errorTypes = ['PermissionDenied', 'PositionUnavailable', 'Timeout'];

	function elmError(rawError)
	{
		return {
			ctor: errorTypes[rawError.code - 1],
			_0: rawError.message
		};
	}

	function jsOptions(options)
	{
		return {
			enableHighAccuracy: options.enableHighAccuracy,
			timeout: options.timeout._0 || Infinity,
			maximumAge: options.maximumAge._0 || 0
		};
	}


	// actually do geolocation stuff

	function current(options)
	{
		return Scheduler.nativeBinding(function(callback) {
			function onSuccess(rawPosition)
			{
				callback(Scheduler.succeed(elmPosition(rawPosition)));
			}
			function onError(rawError)
			{
				callback(Scheduler.fail(elmError(rawError)));
			}
			navigator.geolocation.getCurrentPosition(onSuccess, onError, jsOptions(options));
		});
	}

	function report(options, process)
	{
		return Scheduler.nativeBinding(function(callback)
		{
			function onSuccess(rawPosition)
			{
				A2(Scheduler.send, process, elmPosition(rawPosition));
			}

			function onError(rawError)
			{
				callback(Scheduler.fail(elmError(rawError)));
			}

			var id = navigator.geolocation.watchPosition(onSuccess, onError, jsOptions(options));

			return function() {
				navigator.geolocation.clearWatch(id);
			};
		});
	}

	return localRuntime.Native.Geolocation.values = {
		current: current,
		report: F2(report)
	};
};
