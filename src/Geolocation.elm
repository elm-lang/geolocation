effect module Geolocation where { subscription = MySub } exposing
  ( Location
  , Altitude
  , Movement(..)
  , changes
  , now, nowWith
  , watch, watchWith
  , Options, defaultOptions
  , Error(..)
  )

{-| Find out about where a user’s device is located. [Geolocation API][geo].

[geo]: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation

# Location
@docs Location, Altitude, Movement

# Subscribe to Changes
@docs changes

# Get Current Location
@docs now, Error

# Options
@docs nowWith, Options, defaultOptions

# Low-level Helpers

There are very few excuses to use this. Any normal user should be using
`changes` instead.

@docs watch, watchWith

-}


import Native.Geolocation
import Process
import Task exposing (Task)
import Time exposing (Time)



-- LOCATION


{-| All available details of the device's current location in the world.

  * `latitude` &mdash; the latitude in decimal degrees.
  * `longitude` &mdash; the longitude in decimal degrees.
  * `accuracy` &mdash; the accuracy of the latitude and longitude, expressed in meters.
  * `altitude` &mdash; altitude information, if available.
  * `movement` &mdash; information about how the device is moving, if available.
  * `timestamp` &mdash; the time that this location reading was taken in milliseconds.
-}
type alias Location =
    { latitude : Float
    , longitude : Float
    , accuracy : Float
    , altitude : Maybe Altitude
    , movement : Maybe Movement
    , timestamp : Time
    }


{-| The altitude in meters relative to sea level is held in `value`. The `accuracy` field
describes how accurate `value` is, also in meters.
-}
type alias Altitude =
    { value : Float
    , accuracy : Float
    }


{-| Describes the motion of the device. If the device is not moving, this will
just be `Static`. If the device is moving, you will see the `speed` in meters
per second and the `degreesFromNorth` in degrees.


**Note:** The `degreesFromNorth` value goes clockwise: 0° represents true
north, 90° is east, 180° is south, 270° is west, etc.
-}
type Movement
    = Static
    | Moving { speed : Float, degreesFromNorth : Float }



-- ERRORS


{-| The `now` and `watch` functions may fail for a variaty of reasons.

    * The user may reject the request to use their location.
    * It may be impossible to get a location.
    * If you set a timeout in the `Options` the request may just take too long.

In each case, the browser will provide a string with additional information.
-}
type Error
    = PermissionDenied String
    | LocationUnavailable String
    | Timeout String



-- CURRENT LOCATION


{-| Request the location of the user’s device.

On the first request, the user will need to give permission to access this
information. This task will block until they make a choice. If they do not
give permission, the task will result in a `PermissionDenied` error.
-}
now : Task Error Location
now =
  nowWith defaultOptions


{-| Same as `now` but you can customize exactly how locations are reported.
-}
nowWith : Options -> Task Error Location
nowWith =
  Native.Geolocation.now



-- SUBSCRIBE TO LOCATION CHANGES


{-| This is a low-level API that is used to define things like `changes`.
It is really only useful if you need to make an effect manager of your own.
I feel this will include about 5 people ever.

You provide two functions. One two take some action on movement and one to
take some action on failure. The resulting task will just block forever,
reporting to these two functions. If you would like to kill a `watch` task,
do something like this:

    import Process
    import Task

    killWatch =
      Process.spawn (watch onMove onError)
        |> Task.andThen Process.kill

-}
watch : (Location -> Task Never ()) -> (Error -> Task Never ()) -> Task x Never
watch =
  watchWith defaultOptions


{-| Same as `watch` but you can customize exactly how locations are reported.
-}
watchWith : Options -> (Location -> Task Never ()) -> (Error -> Task Never ()) -> Task x Never
watchWith =
  Native.Geolocation.watch



-- OPTIONS


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



-- SUBSCRIPTIONS


type MySub msg =
  Tagger (Location -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (Tagger tagger) =
  Tagger (tagger >> func)


{-| Subscribe to any location changes. You will only receive updates if the
user is moving around.
-}
changes : (Location -> msg) -> Sub msg
changes tagger =
  subscription (Tagger tagger)



-- EFFECT MANAGER


type alias State msg =
  Maybe
    { subs : List (MySub msg)
    , watcher : Process.Id
    }


init : Task Never (State msg)
init =
  Task.succeed Nothing


onEffects : Platform.Router msg Location -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router subs state =
  case state of
    Nothing ->
      case subs of
        [] ->
          Task.succeed state

        _ ->
          Process.spawn (watch (Platform.sendToSelf router) (\_ -> Task.succeed ()))
            |> Task.andThen (\watcher -> Task.succeed (Just { subs = subs, watcher = watcher }))

    Just {watcher} ->
      case subs of
        [] ->
          Process.kill watcher
            |> Task.andThen (\_ -> Task.succeed Nothing)

        _ ->
          Task.succeed (Just { subs = subs, watcher = watcher })


onSelfMsg : Platform.Router msg Location -> Location -> State msg -> Task Never (State msg)
onSelfMsg router location state =
  case state of
    Nothing ->
      Task.succeed Nothing

    Just {subs} ->
      let
        send (Tagger tagger) =
          Platform.sendToApp router (tagger location)
      in
        Task.sequence (List.map send subs)
          |> Task.andThen (\_ -> Task.succeed state)
