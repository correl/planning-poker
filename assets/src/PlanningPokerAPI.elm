port module PlanningPokerAPI exposing
    ( gotPresence
    , gotReset
    , gotVote
    , joinRoom
    , joinedRoom
    , newProfile
    , reset
    , vote
    )

import Json.Decode exposing (Value)


port joinRoom : { room : String } -> Cmd msg


port newProfile : { playerName : String } -> Cmd msg


port vote : String -> Cmd msg


port reset : () -> Cmd msg


port joinedRoom : (String -> msg) -> Sub msg


port gotPresence : (Value -> msg) -> Sub msg


port gotVote : (Value -> msg) -> Sub msg


port gotReset : (Value -> msg) -> Sub msg
