/*

import Elm.Kernel.Scheduler exposing (binding, succeed, fail, rawSpawn)
import Maybe exposing (Maybe(Just,Nothing))

*/



// LOCATIONS

function _Geolocation_toLocation(rawPosition)
{
	var coords = rawPosition.coords;

	var rawAltitude = coords.altitude;
	var rawAccuracy = coords.altitudeAccuracy;
	var altitude =
		(rawAltitude === null || rawAccuracy === null)
			? __Maybe_Nothing
			: __Maybe_Just({ __$value: rawAltitude, __$accuracy: rawAccuracy });

	var heading = coords.heading;
	var speed = coords.speed;
	var movement =
		(heading === null || speed === null)
			? __Maybe_Nothing
			: __Maybe_Just(
				speed === 0
					? { $: 'Static' }
					: { $: 'Moving', a: { __$speed: speed, __$degreesFromNorth: heading } }
			);

	return {
		__$latitude: coords.latitude,
		__$longitude: coords.longitude,
		__$accuracy: coords.accuracy,
		__$altitude: altitude,
		__$movement: movement,
		__$timestamp: rawPosition.timestamp
	};
}


// ERRORS

var _Geolocation_errorTypes = ['PermissionDenied', 'PositionUnavailable', 'Timeout'];

function _Geolocation_toError(rawError)
{
	return {
		$: _Geolocation_errorTypes[rawError.code - 1],
		a: rawError.message
	};
}


// OPTIONS

function _Geolocation_fromOptions(options)
{
	return {
		enableHighAccuracy: options.__$enableHighAccuracy,
		timeout: options.__$timeout.a,
		maximumAge: options.__$maximumAge.a || 0
	};
}


// GET LOCATION

function _Geolocation_now(options)
{
	return __Scheduler_binding(function(callback)
	{
		function onSuccess(rawPosition)
		{
			callback(__Scheduler_succeed(_Geolocation_toLocation(rawPosition)));
		}

		function onError(rawError)
		{
			callback(__Scheduler_fail(_Geolocation_toError(rawError)));
		}

		navigator.geolocation.getCurrentPosition(onSuccess, onError, _Geolocation_fromOptions(options));
	});
}

function _Geolocation_watch(options, toSuccessTask, toErrorTask)
{
	return __Scheduler_binding(function(callback)
	{
		function onSuccess(rawPosition)
		{
			__Scheduler_rawSpawn(toSuccessTask(_Geolocation_toLocation(rawPosition)));
		}

		function onError(rawError)
		{
			__Scheduler_rawSpawn(toErrorTask(_Geolocation_toError(rawError)));
		}

		var id = navigator.geolocation.watchPosition(onSuccess, onError, _Geolocation_fromOptions(options));

		return function() {
			navigator.geolocation.clearWatch(id);
		};
	});
}
