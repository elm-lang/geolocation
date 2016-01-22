effect module Geo (sub) where



-- SUBSCRIPTIONS


type Sub msg
  = Tagger (Location -> msg)


define subscriptions as
  sub =
    Tagger



-- EFFECT MANAGER


type alias State =
  Maybe
    { subs : List (Location -> msg)
    , reporter : Process Geo.Error Never)
    }


init : Task Never State
init =
  Task.succeed Nothing


userUpdate : Process Never msg -> Process Never Location -> List (Sub msg) -> State -> Task Never State
userUpdate app self subs state =
  case state of
    Nothing ->
      case subs of
        [] ->
          Task.succeed state

        _ :: _ ->
          spawnReporter self
            `andThen` \reporter ->

          Just { reporter = reporter, subs = subs }


    Just state ->
      case state.subs of
        [] ->
          Process.kill state.reporter
            `andThen` \_ ->

          Task.succeed Nothing

        _ :: _ ->
          Task.succeed (Just { reporter = state.reporter, subs = subs }


selfUpdate : Process Never msg -> Process Never Location -> Location -> State -> Task Never State
selfUpdate app self location state =
  case state of
    Nothing ->
      Task.succeed Nothing

    Just {subs} ->
      Task.sequence (List.map (\tagger -> Process.send app (tagger location)) subs)
        `andThen` \_ ->

      Task.succeed state

