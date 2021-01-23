port module PlanningPokerAPI exposing
    ( gotPresenceDiff
    , gotPresenceState
    , gotReset
    , gotReveal
    , gotVote
    , joinRoom
    , newProfile
    , reset
    , reveal
    , updateTheme
    , vote
    )

import Json.Decode as Decode
import Json.Encode as Encode
import PlanningPokerUI as UI


type RoomAction
    = NewProfile { playerName : String }
    | Vote String
    | ResetGame
    | RevealVotes


port joinRoom : { room : String } -> Cmd msg


port roomActions : Encode.Value -> Cmd msg


port saveTheme : String -> Cmd msg


newProfile : { playerName : String } -> Cmd msg
newProfile =
    NewProfile >> encodeAction >> roomActions


vote : String -> Cmd msg
vote =
    Vote >> encodeAction >> roomActions


reset : Cmd msg
reset =
    ResetGame |> encodeAction >> roomActions


reveal : Cmd msg
reveal =
    RevealVotes |> encodeAction >> roomActions


encodeAction : RoomAction -> Encode.Value
encodeAction action =
    let
        wrap : String -> Encode.Value -> Encode.Value
        wrap name data =
            Encode.object
                [ ( "type", Encode.string name )
                , ( "data", data )
                ]
    in
    case action of
        NewProfile { playerName } ->
            wrap "new_profile"
                (Encode.object [ ( "name", Encode.string playerName ) ])

        Vote value ->
            wrap "vote"
                (Encode.object [ ( "value", Encode.string value ) ])

        ResetGame ->
            wrap "reset" (Encode.object [])

        RevealVotes ->
            wrap "reveal" (Encode.object [])


updateTheme : UI.Theme -> Cmd msg
updateTheme theme =
    case theme of
        UI.Light ->
            saveTheme "light"

        UI.Dark ->
            saveTheme "dark"


port gotPresenceState : (Decode.Value -> msg) -> Sub msg


port gotPresenceDiff : (Decode.Value -> msg) -> Sub msg


port gotVote : (Decode.Value -> msg) -> Sub msg


port gotReveal : (Decode.Value -> msg) -> Sub msg


port gotReset : (Decode.Value -> msg) -> Sub msg
