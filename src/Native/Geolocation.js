Elm.Native.Geolocation = {};
Elm.Native.Geolocation.make = function(localRuntime) {

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Geolocation = localRuntime.Native.Geolocation || {};
    if (localRuntime.Native.Geolocation.values)
    {
        return localRuntime.Native.Geolocation.values;
    }

    var Maybe = Elm.Maybe.make(localRuntime);
    var Task = Elm.Native.Task.make(localRuntime);


    // JS values to Elm values

    function maybe(value)
    {
        return value === null ? Maybe.Nothing : Maybe.Just(value);
    }

    function elmPosition(rawPosition)
    {
        var coords = rawPosition.coords;
        return {
            latitude: coords.latitude,
            longitude: coords.longitude,
            altitude: maybe(coords.altitude),
            accuracy: coords.accuracy,
            altitudeAccuracy: maybe(coords.altitudeAccuracy),
            heading: maybe(coords.heading),
            speed: maybe(coords.speed),
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
        return Task.asyncFunction(function(callback) {
            function onSuccess(rawPosition)
            {
                callback(Task.succeed(elmPosition(rawPosition)));
            }
            function onError(rawError)
            {
                callback(Task.fail(elmError(rawError)));
            }
            navigator.geolocation.getCurrentPosition(onSuccess, onError, jsOptions(options));
        });
    }

    function subscribe(options, successTask, errorTask)
    {
        return Task.asyncFunction(function(callback) {
            function onSuccess(rawPosition)
            {
                Task.spawn(successTask(elmPosition(rawPosition)));
            }
            function onError(rawError)
            {
                Task.spawn(errorTask(elmError(rawError)));
            }
            var id = navigator.geolocation.watchPosition(onSuccess, onError, jsOptions(options));
            callback(Task.succeed(id));
        });
    }

    function unsubscribe(id)
    {
        return Task.asyncFunction(function(callback) {
            navigator.geolocation.clearWatch(id);
            callback(Task.succeed(Utils.Tuple0));
        });
    }

    return localRuntime.Native.Geolocation.values = {
        current: current,
        subscribe: F3(subscribe),
        unsubscribe: unsubscribe
    };
};
