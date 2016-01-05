module Geolocation
    ( Location
    , Movement
    , current
    , subscribe
    , unsubscribe
    , Options
    , currentWith
    , subscribeWith
    , defaultOptions
    , Error(..)
    )
    where

{-| Primitive bindings to the web's [Geolocation API][geo]. You probably want
to use something higher-level than this, like the elm-effects API for
geolocation.

[geo]: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation

# Location
@docs Location, Movement

# Requesting a Location
@docs current, subscribe, unsubscribe

# Errors
@docs Error

# Options
@docs currentWith, subscribeWith, Options, defaultOptions

-}


import Native.Geolocation
import Task exposing (Task)
import Time exposing (Time)


{-| All available details of the device's current location in the world.

  * `latitude` &mdash; the latitude in decimal degrees.
  * `longitude` &mdash; the longitude in decimal degrees.
  * `accuracy` &mdash; the accuracy of the latitude and longitude, expressed in meters.
  * `altitude` &mdash; the altitude relative to sea level and its level of accuracy (all in meters) if available.
  * `movement` &mdash; information about how the device is moving, if available.
  * `timestamp` &mdash; the time that this location reading was taken in milliseconds.
-}
type alias Location =
    { latitude : Float
    , longitude : Float
    , accuracy : Float
    , altitude : Maybe { value : Float, accuracy : Float }
    , movement : Maybe Movement
    , timestamp : Time
    }


{-| Describes the motion of the device. If the device is not moving, this will
just be `Static`. If the device is moving, you will see the `speed` in meters
per second and the `degreesFromNorth` in degrees.


**Note:** The `degreesFromNorth` value goes clockwise: 0° represents true
north, 90° is east, 180° is south, 270° is west, etc.
-}
type Movement = Static | Moving { speed : Float, degreesFromNorth : Float }



{-| The `current` and `subscribe` functions may fail for a variaty of reasons.

    * The user may reject the request to use their location.
    * It may be impossible to get a location.
    * If you set a timeout in the `Options` the request may just take to long.

In each case, the browser will provide a string with additional information.
-}
type Error
    = PermissionDenied String
    | LocationUnavailable String
    | Timeout String


{-| Request the current position of the user's device. On the first request,
the user will need to give permission to access this information.
-}
current : Task Error Location
current =
  currentWith defaultOptions


{-| Subscribe to changes in the device's position. You provide two callbacks.
One for when a location has been successfully reported, and another for when
there has been some sort of problem.

When you run the task to create a subscription, you will get back an integer
that uniquely identifies this subscription. You can give that identifier to
`unsubscribe` to stop getting updates.
-}
subscribe : (Location -> Task x a) -> (Error -> Task y b) -> Task z Int
subscribe =
  subscribeWith defaultOptions


{-| Each subscription is uniquely identified by an integer. You can cancel a
subscription by giving that integer to `unsubscribe`.
-}
unsubscribe : Int -> Task x ()
unsubscribe =
  Native.Geolocation.unsubscribe



-- WITH OPTIONS


{-| Same as `current` but you can customize exactly how locations are reported.
-}
currentWith : Options -> Task Error Location
currentWith =
  Native.Geolocation.current


{-| Same as `subscribe` but you can customize exactly how locations are reported.
-}
subscribeWith : Options -> (Location -> Task x a) -> (Error -> Task y b) -> Task z Int
subscribeWith =
  Native.Geolocation.subscribe


{-| There are a couple options you can mess with when requesting location data.

    * `enableHighAccuracy` &mdash; When enabled, the device will attempt to provide
      a more accurate location. This can result in slower response times or
      increased power consumption (with a GPS chip on a mobile device for example).
      When disabled, the device can take the liberty to save resources by responding
      more quickly and/or using less power.
    * `timeout` &mdash; Requesting a location can take time, so you have the option
      to provide an upper bound in milliseconds on that wait.
    * `maximumAge` &mdash; This API can return cached locations. If this is set
      to `Just 400` you may get cached locations as long as they were read in the
      last 400 milliseconds. If this is `Nothing` then the device must attempt
      to retrieve the current location every time.
-}
type alias Options =
    { enableHighAccuracy : Bool
    , timeout : Maybe Int
    , maximumAge : Maybe Int
    }


{-| The options you will want in 99% of cases. This will get you faster
results, less battery drain, no surprise failures due to timeouts, and no
surprising cached results.

    { enableHighAccuracy = False
    , timeout = Nothing
    , maximumAge = Nothing
    }
-}
defaultOptions : Options
defaultOptions =
    { enableHighAccuracy = False
    , timeout = Nothing
    , maximumAge = Nothing
    }
