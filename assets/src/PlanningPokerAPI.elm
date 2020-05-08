port module PlanningPokerAPI exposing
    ( gotPresence
    , joinRoom
    , joinedRoom
    , newProfile
    , vote
    )

import Json.Decode exposing (Value)


port joinRoom : { room : String } -> Cmd msg


port newProfile : { playerName : String } -> Cmd msg


port vote : String -> Cmd msg


port joinedRoom : (String -> msg) -> Sub msg


port gotPresence : (Value -> msg) -> Sub msg
