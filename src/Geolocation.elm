module Geolocation
    ( Position, Coords
    , currentPosition
    , watchPosition, clearWatch
    , Options, defaultOptions
    , Error(..)
    ) where

import Native.Geolocation
import Promise (Promise)
import Time (Time)

{-|

# Current Position
@docs currentPosition, Options, defaultOptions, Position, Coords, Error

# Watch Position Over Time
@docs watchPosition, clearWatch

-}

type alias Position =
    { coords : Coords
    , timestamp : Time
    }


{-| Coordinate data provides as much information as possible for a given
device.

  * `latitude` &mdash; the latitude in decimal degrees.
  * `longitude` &mdash; the longitude in decimal degrees.
  * `altitude` &mdash; the altitude in meters, relative to sea level, if the
    implementation cannot provide the data.
  * `accuracy` &mdash; the accuracy of the latitude and longitude properties,
    expressed in meters.
  * `altitudeAccuracy` &mdash; the accuracy of the altitude expressed in
    meters, if available.
  * `heading` &mdash; the direction in which the device is traveling, if
    available. This value, specified in degrees, indicates how far off from
    heading due north the device is. 0 degrees represents true north, 90
    degrees is east, 270 degrees is west, and everything in between. If speed
    is 0, heading is NaN.
  * `speed` &mdash; the velocity of the device in meters per second, if available.
-}
type alias Coords =
    { latitude : Float
    , longitude : Float
    , altitude : Maybe Float
    , accuracy : Float
    , altitudeAccuracy : Maybe Float
    , heading : Maybe Float
    , speed : Maybe Float
    }


type Error
    = PermissionDenied String
    | PositionUnavailable String
    | Timeout String


currentPosition : Options -> Promise Error Position
currentPosition =
  Native.Geolocation.currentPosition


watchPosition : Options -> (Position -> Promise x a) -> (Error -> Promise y b) -> Promise z Int
watchPosition =
  Native.Geolocation.watchPosition


clearWatch : Int -> Promise x ()
clearWatch =
  Native.Geolocation.clearWatch


type alias Options =
    { enableHighAccuracy : Bool
    , timeout : Maybe Int
    , maximumAge : Maybe Int
    }


defaultOptions : Options
defaultOptions =
    { enableHighAccuracy = False
    , timeout = Nothing
    , maximumAge = Nothing
    }