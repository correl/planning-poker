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
    { state : State
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
    | GotPresence Decode.Value
    | GotVote Decode.Value
    | GotReveal
    | GotReset


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


type UserLevel
    = Moderator
    | Participant


type Vote
    = Hidden (Maybe String)
    | Revealed (Maybe String)


init :
    { id : String
    , player : String
    , roomName : String
    , playerName : String
    }
    -> ( Model, Cmd Msg )
init { id, player, roomName, playerName } =
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
    ( { room = room
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
            ( { model | state = Playing }
            , API.newProfile { playerName = model.playerName }
            )

        GotPresence value ->
            case Decode.decodeValue playersDecoder value of
                Ok players ->
                    let
                        newRoom =
                            { room | players = players }
                    in
                    ( { model | room = newRoom }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GotVote value ->
            case Decode.decodeValue voteDecoder value of
                Ok ( player, vote ) ->
                    let
                        newPlayers =
                            Dict.update player
                                (Maybe.map (\p -> { p | vote = Just vote }))
                                room.players

                        newRoom =
                            { room | players = newPlayers }
                    in
                    ( { model | room = newRoom }, Cmd.none )

                _ ->
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


view : { height : Int, width : Int } -> Model -> Document Msg
view dimensions model =
    let
        device =
            classifyDevice dimensions
                |> Debug.log "device"

        playerName =
            Dict.get model.player model.room.players
                |> Maybe.map .name
                |> Maybe.withDefault model.playerName
    in
    case model.state of
        Playing ->
            UI.toDocument
                { title = model.room.name
                , body =
                    [ navBar { title = model.room.name, playerName = playerName }
                    , viewRoom device model
                    ]
                }

        Joining ->
            UI.toDocument
                { title = model.room.name
                , body =
                    [ navBar { title = model.room.name, playerName = playerName }
                    , joinForm model.room model.playerName
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
            column [ width fill, spacing 20 ]
                [ viewPlayers (Dict.values model.room.players) model.showVotes
                , el [ width (fillPortion 3), alignTop ] <|
                    viewCards myVote
                , moderatorTools model
                ]

        _ ->
            column [ width fill, spacing 20 ]
                [ row
                    [ width fill ]
                    [ el [ width (fillPortion 3), alignTop ] <|
                        viewCards myVote
                    , column [ width (fillPortion 1), alignTop, spacing 50 ] <|
                        [ viewPlayers (Dict.values model.room.players) model.showVotes
                        , moderatorTools model
                        ]
                    ]
                ]


navBar : { title : String, playerName : String } -> Element Msg
navBar { title, playerName } =
    row
        [ Background.color UI.colors.primary
        , height (px 50)
        , width fill
        , padding 10
        ]
        [ el
            [ Font.alignLeft
            , Font.color UI.colors.background
            , width fill
            ]
            (text title)
        , el
            [ Font.alignRight
            , Font.color UI.colors.background
            ]
            (text playerName)
        ]


viewCards : Maybe String -> Element Msg
viewCards selected =
    let
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
                        UI.colors.selected

                    else
                        UI.colors.background
                , Font.size 50
                ]
                { onPress = Just (Vote value)
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
        { data = playerList
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
        [ UI.actionButton
            [ centerX ]
            { isActive = not model.showVotes
            , onPress = Reveal
            , label = text "Reveal"
            }
        , UI.actionButton
            [ centerX ]
            { isActive = True
            , onPress = Reset
            , label = text "Reset"
            }
        ]


joinForm : Room -> String -> Element Msg
joinForm room playerName =
    let
        players =
            Dict.values room.players
                |> List.map .name
    in
    column [ width fill, spacing 20, centerX, centerY ]
        [ UI.heroText [ centerX ] "Welcome!"
        , el [ centerX ] (text "Tell us who you are")
        , Input.text [ centerX, width (px 300), Font.center ]
            { onChange = PlayerNameChanged
            , text = playerName
            , label = Input.labelHidden "Your name"
            , placeholder = Just (Input.placeholder [] (text "Your name"))
            }
        , UI.actionButton [ centerX ]
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
        [ API.gotPresence GotPresence
        , API.gotReset (\_ -> GotReset)
        , API.gotReveal (\_ -> GotReveal)
        , API.gotVote GotVote
        ]


playersDecoder : Decode.Decoder (Dict String Player)
playersDecoder =
    let
        presence =
            Decode.map2 (Player Participant)
                (Decode.field "name" Decode.string)
                (Decode.field "vote" (Decode.nullable Decode.string))
    in
    Decode.dict presence


voteDecoder : Decode.Decoder ( String, String )
voteDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "player" Decode.string)
        (Decode.field "vote" Decode.string)
