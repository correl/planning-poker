module PlanningPokerRoom exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Json.Decode as Decode
import PlanningPokerAPI as API
import PlanningPokerUI as UI


type alias Model =
    { theme : UI.Theme
    , state : State
    , room : Room
    , player : String
    , playerName : String
    , showVotes : Bool
    }


type State
    = Joining
    | Playing


type Msg
    = Vote String
    | Reset
    | Reveal
    | PlayerNameChanged String
    | JoinRoom
    | GotPresence (Result Decode.Error Presence)
    | GotVote (Result Decode.Error ReceivedVote)
    | GotReveal
    | GotReset
    | UpdateTheme UI.Theme


type Presence
    = PresenceState (Dict String Player)
    | PresenceDiff (Diff (Dict String Player))


type alias Diff a =
    { joins : a
    , leaves : a
    }


type alias Room =
    { id : String
    , name : String
    , players : Dict String Player
    }


type alias Player =
    { level : UserLevel
    , name : String
    , vote : Maybe String
    }


type alias ReceivedVote =
    { player : String
    , value : String
    }


type UserLevel
    = Moderator
    | Participant


type Vote
    = Hidden (Maybe String)
    | Revealed (Maybe String)


init :
    { theme : UI.Theme
    , id : String
    , player : String
    , roomName : String
    , playerName : String
    }
    -> ( Model, Cmd Msg )
init { theme, id, player, roomName, playerName } =
    let
        room =
            { id = id
            , name = roomName
            , players = Dict.empty
            }

        ( state, cmd ) =
            if String.isEmpty playerName then
                ( Joining, API.joinRoom { room = id } )

            else
                ( Playing
                , Cmd.batch
                    [ API.joinRoom { room = id }
                    , API.newProfile { playerName = playerName }
                    ]
                )
    in
    ( { theme = theme
      , room = room
      , state = state
      , player = player
      , playerName = playerName
      , showVotes = False
      }
    , cmd
    )


update : Nav.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
    let
        room =
            model.room
    in
    case msg of
        Vote value ->
            ( model
            , API.vote value
            )

        Reveal ->
            ( model
            , API.reveal
            )

        Reset ->
            ( model
            , API.reset
            )

        PlayerNameChanged newName ->
            ( { model | playerName = newName }, Cmd.none )

        JoinRoom ->
            if not (String.isEmpty model.playerName) then
                ( { model | state = Playing }
                , API.newProfile { playerName = model.playerName }
                )

            else
                ( model, Cmd.none )

        GotPresence (Ok (PresenceState players)) ->
            let
                newRoom =
                    { room | players = players }
            in
            ( { model | room = newRoom }, Cmd.none )

        GotPresence (Ok (PresenceDiff { joins, leaves })) ->
            let
                newPlayers =
                    room.players
                        |> Dict.filter (\id _ -> not (Dict.member id leaves))
                        |> Dict.union joins

                newRoom =
                    { room | players = newPlayers }
            in
            ( { model | room = newRoom }, Cmd.none )

        GotPresence _ ->
            ( model, Cmd.none )

        GotVote (Ok { player, value }) ->
            let
                newPlayers =
                    Dict.update player
                        (Maybe.map (\p -> { p | vote = Just value }))
                        room.players

                newRoom =
                    { room | players = newPlayers }
            in
            ( { model | room = newRoom }, Cmd.none )

        GotVote (Err _) ->
            ( model, Cmd.none )

        GotReveal ->
            ( { model | showVotes = True }
            , Cmd.none
            )

        GotReset ->
            let
                newPlayers =
                    room.players
                        |> Dict.map (\k v -> { v | vote = Nothing })

                newRoom =
                    { room | players = newPlayers }
            in
            ( { model
                | showVotes = False
                , room = newRoom
              }
            , Cmd.none
            )

        UpdateTheme theme ->
            ( { model | theme = theme }, API.updateTheme theme )


view : { height : Int, width : Int } -> Model -> Document Msg
view dimensions model =
    let
        device =
            classifyDevice dimensions

        playerName =
            Dict.get model.player model.room.players
                |> Maybe.map .name
                |> Maybe.withDefault model.playerName
    in
    case model.state of
        Playing ->
            UI.toDocument model.theme
                { title = model.room.name
                , body =
                    [ navBar model.theme { title = model.room.name, playerName = playerName }
                    , viewRoom device model
                    , UI.themePicker model.theme UpdateTheme
                    ]
                }

        Joining ->
            UI.toDocument model.theme
                { title = model.room.name
                , body =
                    [ navBar model.theme { title = model.room.name, playerName = playerName }
                    , joinForm model.theme model.room model.playerName
                    , UI.themePicker model.theme UpdateTheme
                    ]
                }


viewRoom : Device -> Model -> Element Msg
viewRoom device model =
    let
        myVote =
            Dict.get model.player model.room.players
                |> Maybe.andThen .vote
    in
    case device.class of
        Phone ->
            column [ width fill, spacing 20, centerY ]
                [ viewPlayers (Dict.values model.room.players) model.showVotes
                , el [ width (fillPortion 3), alignTop ] <|
                    viewCards model myVote
                , moderatorTools model
                ]

        _ ->
            column [ width fill, spacing 20, centerY, alignTop ]
                [ row
                    [ width fill ]
                    [ el [ width (fillPortion 3), alignTop ] <|
                        viewCards model myVote
                    , column [ width (fillPortion 1), alignTop, spacing 50 ] <|
                        [ viewPlayers (Dict.values model.room.players) model.showVotes
                        , moderatorTools model
                        ]
                    ]
                ]


navBar : UI.Theme -> { title : String, playerName : String } -> Element Msg
navBar theme { title, playerName } =
    UI.navBar theme
        [ el
            [ Font.alignLeft
            , width fill
            ]
            (text title)
        , el
            [ Font.alignRight
            ]
            (text playerName)
        ]


viewCards : Model -> Maybe String -> Element Msg
viewCards model selected =
    let
        enabled =
            not model.showVotes

        selectedColor =
            if enabled then
                (UI.colors model.theme).selected

            else
                (UI.colors model.theme).disabled

        card value =
            Input.button
                [ width (px 100)
                , height (px 200)
                , padding 20
                , centerX
                , Border.solid
                , Border.width 1
                , Border.rounded 10
                , Background.color <|
                    if selected == Just value then
                        selectedColor

                    else
                        (UI.colors model.theme).background
                , Font.size 50
                ]
                { onPress =
                    if enabled then
                        Just (Vote value)

                    else
                        Nothing
                , label = el [ centerX, centerY ] (text value)
                }
    in
    wrappedRow [ centerX, width fill, spacing 30 ] <|
        List.map card
            [ "1"
            , "2"
            , "3"
            , "5"
            , "8"
            , "13"
            , "?"
            , "☕"
            ]


viewPlayers : List Player -> Bool -> Element Msg
viewPlayers playerList showVotes =
    table [ width fill ]
        { data = List.sortBy .name playerList
        , columns =
            [ { header = none
              , width = fill
              , view =
                    \player ->
                        el
                            [ padding 10
                            , Border.widthEach
                                { bottom = 1
                                , left = 0
                                , right = 0
                                , top = 0
                                }
                            ]
                            (text player.name)
              }
            , { header = none
              , width = px 50
              , view =
                    \player ->
                        let
                            vote =
                                if showVotes then
                                    player.vote

                                else
                                    Maybe.map (\_ -> "✓") player.vote
                        in
                        el
                            [ padding 10
                            , Border.widthEach
                                { bottom = 1
                                , left = 0
                                , right = 0
                                , top = 0
                                }
                            , Font.alignRight
                            , Font.bold
                            ]
                            (text <| Maybe.withDefault " " vote)
              }
            ]
        }


moderatorTools : Model -> Element Msg
moderatorTools model =
    row [ centerX, spacing 20 ]
        [ UI.actionButton model.theme
            [ centerX ]
            { isActive = not model.showVotes
            , onPress = Reveal
            , label = text "Reveal"
            }
        , UI.actionButton model.theme
            [ centerX ]
            { isActive = True
            , onPress = Reset
            , label = text "Reset"
            }
        ]


joinForm : UI.Theme -> Room -> String -> Element Msg
joinForm theme room playerName =
    let
        players =
            Dict.values room.players
                |> List.map .name
    in
    column [ width fill, spacing 20, centerX, centerY ]
        [ UI.heroText [ centerX ] "Welcome!"
        , el [ centerX ] (text "Tell us who you are")
        , Input.text
            [ centerX
            , width (px 300)
            , Font.center
            , UI.onEnter JoinRoom
            ]
            { onChange = PlayerNameChanged
            , text = playerName
            , label = Input.labelHidden "Your name"
            , placeholder = Just (Input.placeholder [] (text "Your name"))
            }
        , UI.actionButton theme
            [ centerX ]
            { isActive = not (String.isEmpty playerName)
            , onPress = JoinRoom
            , label = text "Join!"
            }
        , el [ centerX ]
            (text <|
                case players of
                    [] ->
                        "Nobody else has joined yet."

                    [ player ] ->
                        player ++ " is already here!"

                    player :: rest ->
                        if List.length players <= 3 then
                            String.join ", " rest
                                ++ ", and "
                                ++ player
                                ++ " are already here!"

                        else
                            String.fromInt (List.length players)
                                ++ " People are already here"
            )
        ]


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ API.gotPresenceState (decodePresenceState >> GotPresence)
        , API.gotPresenceDiff (decodePresenceDiff >> GotPresence)
        , API.gotReset (\_ -> GotReset)
        , API.gotReveal (\_ -> GotReveal)
        , API.gotVote (decodeVote >> GotVote)
        ]


decodePresenceState : Decode.Value -> Result Decode.Error Presence
decodePresenceState value =
    Decode.decodeValue playersDecoder value
        |> Result.map PresenceState


decodePresenceDiff : Decode.Value -> Result Decode.Error Presence
decodePresenceDiff value =
    let
        decoder =
            Decode.map PresenceDiff <|
                Decode.map2 Diff
                    (Decode.field "joins" playersDecoder)
                    (Decode.field "leaves" playersDecoder)
    in
    Decode.decodeValue decoder value


decodeVote : Decode.Value -> Result Decode.Error ReceivedVote
decodeVote value =
    let
        decoder =
            Decode.map2 ReceivedVote
                (Decode.field "player" Decode.string)
                (Decode.field "vote" Decode.string)
    in
    Decode.decodeValue decoder value


playersDecoder : Decode.Decoder (Dict String Player)
playersDecoder =
    let
        presence =
            Decode.map2 (Player Participant)
                (Decode.field "name"
                    (Decode.nullable Decode.string
                        |> Decode.map (Maybe.withDefault "")
                    )
                )
                (Decode.field "vote" (Decode.nullable Decode.string))
    in
    Decode.dict presence
