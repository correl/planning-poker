port module PlanningPokerAPI exposing
    ( gotPresence
    , joinRoom
    , joinedRoom
    )

import Json.Decode exposing (Value)


port joinRoom : { room : String, playerName : String } -> Cmd msg


port joinedRoom : (String -> msg) -> Sub msg


port gotPresence : (Value -> msg) -> Sub msg
