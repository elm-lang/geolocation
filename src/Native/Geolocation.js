Elm.Native.Geolocation = {};
Elm.Native.Geolocation.make = function(localRuntime) {

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Geolocation = localRuntime.Native.Geolocation || {};
    if (localRuntime.Native.Geolocation.values)
    {
        return localRuntime.Native.Geolocation.values;
    }

    var Maybe = Elm.Maybe.make(localRuntime);
    var Promise = Elm.Native.Promise.make(localRuntime);


    // JS values to Elm values

    function maybe(value) {
        return value === null
            ? Maybe.Nothing
            : Maybe.Just(value);
    }

    function elmPosition(rawPosition) {
        var coords = rawPosition.coords;
        return {
            _: {},
            timestamp: rawPosition.timestamp,
            coords: {
                _: {},
                latitude: coords.latitude,
                longitude: coords.longitude,
                altitude: maybe(coords.altitude),
                accuracy: coords.accuracy,
                altitudeAccuracy: maybe(coords.altitudeAccuracy),
                heading: maybe(coords.heading),
                speed: maybe(coords.speed)
            }
        };
    }

    var errorTypes = ['PermissionDenied', 'PositionUnavailable', 'Timeout'];

    function elmError(rawError) {
        return {
            ctor: errorTypes[rawError.code - 1],
            _0: rawError.message
        };
    }

    function jsOptions(options) {
        return {
            enableHighAccuracy: options.enableHighAccuracy,
            timeout: options.timeout._0 || Infinity,
            maximumAge: options.maximumAge._0
        };
    }


    // actually do geolocation stuff

    function currentPosition(options) {
        return Promise.asyncFunction(function(callback) {
            function onSuccess(rawPosition) {
                callback(Promise.succeed(elmPosition(rawPosition)));
            }
            function onError(rawError) {
                callback(Promise.fail(elmError(rawError)));
            }
            navigator.geolocation.getCurrentPosition(
                onSuccess, onError, jsOptions(options)
            );
        });
    }

    function watchPosition(options, successPromise, errorPromise) {
        return Promise.asyncFunction(function(callback) {
            function onSuccess(rawPosition) {
                Promise.spawn(successPromise(elmPosition(rawPosition)));
            }
            function onError(rawError) {
                Promise.spawn(errorPromise(elmError(rawError)));
            }
            var id = navigator.geolocation.watchPosition(
                onSuccess, onError, jsOptions(options)
            );
            callback(Promise.succeed(id));
        });
    }

    function clearWatch(id) {
        return Promise.asyncFunction(function(callback) {
            navigator.geolocation.clearWatch(id);
            callback(Promise.succeed(Utils.Tuple0));
        });
    }

    return localRuntime.Native.Geolocation.values = {
        currentPosition: currentPosition,
        watchPosition: F3(watchPosition),
        clearWatch: clearWatch
    };
};
