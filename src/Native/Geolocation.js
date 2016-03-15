//import Maybe, Native.Scheduler //

var _elm_lang$geolocation$Native_Geolocation = function() {


// LOCATIONS

function toLocation(rawPosition)
{
	var coords = rawPosition.coords;

	var rawAltitude = coords.altitude;
	var rawAccuracy = coords.altitudeAccuracy;
	var altitude =
		(rawAltitude === null || rawAccuracy === null)
			? _elm_lang$core$Maybe$Nothing
			: _elm_lang$core$Maybe$Just({ value: rawAltitude, accuracy: rawAccuracy });

	var heading = coords.heading;
	var speed = coords.speed;
	var movement =
		(heading === null || speed === null)
			? _elm_lang$core$Maybe$Nothing
			: _elm_lang$core$Maybe$Just(
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


// ERRORS

var errorTypes = ['PermissionDenied', 'PositionUnavailable', 'Timeout'];

function toError(rawError)
{
	return {
		ctor: errorTypes[rawError.code - 1],
		_0: rawError.message
	};
}


// OPTIONS

function fromOptions(options)
{
	return {
		enableHighAccuracy: options.enableHighAccuracy,
		timeout: options.timeout._0 || Infinity,
		maximumAge: options.maximumAge._0 || 0
	};
}


// GET LOCATION

function now(options)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		function onSuccess(rawPosition)
		{
			callback(_elm_lang$core$Native_Scheduler.succeed(toLocation(rawPosition)));
		}

		function onError(rawError)
		{
			callback(_elm_lang$core$Native_Scheduler.fail(toError(rawError)));
		}

		navigator.geolocation.getCurrentPosition(onSuccess, onError, fromOptions(options));
	});
}

function watch(options, toSuccessTask, toErrorTask)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		function onSuccess(rawPosition)
		{
			var location = toLocation(rawPosition);
			var task = toSuccessTask(location);
			_elm_lang$core$Native_Scheduler.rawSpawn(task);
		}

		function onError(rawError)
		{
			var error = toError(rawError);
			var task = toErrorTask(error);
			_elm_lang$core$Native_Scheduler.rawSpawn(task);
		}

		var id = navigator.geolocation.watchPosition(onSuccess, onError, fromOptions(options));

		return function() {
			navigator.geolocation.clearWatch(id);
		};
	});
}

return {
	now: now,
	watch: F3(watch)
};

}();
