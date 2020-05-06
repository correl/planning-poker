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
    { room : Maybe Room
    , player : String
    , playerName : String
    , showVotes : Bool
    }


type Msg
    = Vote String
    | Reset
    | Reveal
    | PlayerNameChanged String
    | JoinRoom
    | GotPresence Decode.Value


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
    in
    ( { room = Just room
      , player = player
      , playerName = playerName
      , showVotes = False
      }
    , Cmd.none
    )


update : Nav.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
    case model.room of
        Just room ->
            case msg of
                Vote value ->
                    ( { model
                        | room =
                            Just
                                { room
                                    | players =
                                        Dict.update
                                            model.player
                                            (Maybe.map (\p -> { p | vote = Just value }))
                                            room.players
                                }
                      }
                    , Cmd.none
                    )

                Reveal ->
                    ( { model | showVotes = True }
                    , Cmd.none
                    )

                Reset ->
                    ( { model
                        | room =
                            Just
                                { room
                                    | players =
                                        Dict.map
                                            (\k v -> { v | vote = Nothing })
                                            room.players
                                }
                        , showVotes = False
                      }
                    , Cmd.none
                    )

                PlayerNameChanged newName ->
                    ( { model | playerName = newName }, Cmd.none )

                JoinRoom ->
                    let
                        newRoom =
                            { room
                                | players =
                                    Dict.insert model.player
                                        { level = Participant
                                        , name = model.playerName
                                        , vote = Nothing
                                        }
                                        room.players
                            }
                    in
                    ( model
                    , API.joinRoom { room = room.id, playerName = model.playerName }
                    )

                GotPresence value ->
                    case Decode.decodeValue playersDecoder value of
                        Ok players ->
                            let
                                newRoom =
                                    { room | players = players }
                            in
                            ( { model | room = Just newRoom }, Cmd.none )

                        Err _ ->
                            ( model, Cmd.none )

        Nothing ->
            case msg of
                _ ->
                    ( model, Cmd.none )


view : Model -> Document Msg
view model =
    case model.room of
        Just room ->
            let
                maybePlayer =
                    Dict.get model.player room.players
            in
            case maybePlayer of
                Just player ->
                    UI.toDocument
                        { title = room.name
                        , body =
                            [ navBar { title = room.name, playerName = player.name }
                            , viewRoom model.player room model.showVotes
                            ]
                        }

                Nothing ->
                    UI.toDocument
                        { title = room.name
                        , body =
                            [ navBar { title = room.name, playerName = "" }
                            , joinForm room model.playerName
                            ]
                        }

        _ ->
            UI.toDocument
                { title = "Loading Room..."
                , body =
                    [ UI.heroText [ centerX, centerY ] "Loading..."
                    ]
                }


viewRoom : String -> Room -> Bool -> Element Msg
viewRoom player room showVotes =
    let
        myVote =
            Dict.get player room.players
                |> Maybe.andThen .vote
    in
    column [ width fill, spacing 20 ]
        [ row
            [ width fill ]
            [ el [ width (fillPortion 3), alignTop ] <|
                viewCards myVote
            , el [ width (fillPortion 1), alignTop ] <|
                viewPlayers (Dict.values room.players) showVotes
            ]
        , moderatorTools
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
    row [ width fill, spacing 30 ] <|
        List.map card [ "1", "3", "5", "8", "13" ]


viewPlayers : List Player -> Bool -> Element Msg
viewPlayers playerList showVotes =
    table [ width fill ]
        { data = playerList
        , columns =
            [ { header = none
              , width = fill
              , view =
                    \player ->
                        el [ padding 10 ]
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
                            , Font.alignRight
                            ]
                            (text <| Maybe.withDefault " " vote)
              }
            ]
        }


moderatorTools : Element Msg
moderatorTools =
    row [ centerX, spacing 20 ]
        [ UI.actionButton
            [ centerX ]
            { isActive = True
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
    API.gotPresence GotPresence


type alias Presence =
    { metas : List PresenceMeta }


type alias PresenceMeta =
    { name : String
    , online_at : String
    , phx_ref : String
    }


playersDecoder : Decode.Decoder (Dict String Player)
playersDecoder =
    let
        meta =
            Decode.field "name" Decode.string

        presence =
            Decode.field "metas" (Decode.index 0 meta)

        toPlayer id name =
            { level = Participant
            , name = name
            , vote = Nothing
            }
    in
    Decode.dict presence
        |> Decode.map (Dict.map toPlayer)
