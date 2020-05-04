module PlanningPokerRoom exposing (Model, Msg, init, update, view)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import PlanningPokerUI as UI


type alias Model =
    { room : Maybe Room
    , player : String
    , playerName : String
    }


type Msg
    = Vote String
    | Reset
    | PlayerNameChanged String
    | JoinRoom


type alias Room =
    { id : String
    , name : String
    , players : Dict String Player
    }


type UserLevel
    = Moderator
    | Participant


type alias Player =
    { level : UserLevel
    , name : String
    , vote : Maybe String
    }


init : { room : String, roomName : String, playerName : String } -> ( Model, Cmd Msg )
init { room, roomName, playerName } =
    let
        preparedRooms =
            Dict.fromList
                [ -- Room created from mocked entry page
                  ( "a0fd1422-abd9-434e-9d7c-883294b2992c"
                  , { id = "a0fd1422-abd9-434e-9d7c-883294b2992c"
                    , name = roomName
                    , players =
                        Dict.fromList
                            [ ( "00000000-0000-0000-0000-000000000000"
                              , { level = Moderator, name = playerName, vote = Nothing }
                              )
                            , ( "44db0a59-28bb-4b9f-8e5d-a46f2c2a3266"
                              , { level = Participant, name = "John", vote = Nothing }
                              )
                            , ( "69b8b450-bc2a-4eeb-b056-91c7aa4ba528"
                              , { level = Participant, name = "Jane", vote = Nothing }
                              )
                            ]
                    }
                  )
                , -- Room created from direct url access (unjoined)
                  ( "joinable"
                  , { id = "a0fd1422-abd9-434e-9d7c-883294b2992c"
                    , name = "Today's Grooming Session"
                    , players =
                        Dict.fromList
                            [ ( "ffffffff-ffff-ffff-ffff-ffffffffffff"
                              , { level = Moderator, name = "Pat", vote = Nothing }
                              )
                            , ( "44db0a59-28bb-4b9f-8e5d-a46f2c2a3266"
                              , { level = Participant, name = "John", vote = Nothing }
                              )
                            , ( "69b8b450-bc2a-4eeb-b056-91c7aa4ba528"
                              , { level = Participant, name = "Jane", vote = Nothing }
                              )
                            ]
                    }
                  )
                ]
    in
    ( { room = Dict.get room preparedRooms
      , player = "00000000-0000-0000-0000-000000000000"
      , playerName = playerName
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
                    ( { model | room = Just newRoom }, Cmd.none )

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
                            , viewRoom model.player room
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


viewRoom : String -> Room -> Element Msg
viewRoom player room =
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
                viewPlayers (Dict.values room.players)
            ]
        , moderatorTools
        ]


navBar : { title : String, playerName : String } -> Element Msg
navBar { title, playerName } =
    row
        [ Background.color UI.blue
        , height (px 50)
        , width fill
        , padding 10
        ]
        [ el
            [ Font.alignLeft
            , Font.color UI.white
            , width fill
            ]
            (text title)
        , el
            [ Font.alignRight
            , Font.color UI.white
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
                        UI.blue

                    else
                        UI.white
                , Font.size 50
                ]
                { onPress = Just (Vote value)
                , label = el [ centerX, centerY ] (text value)
                }
    in
    row [ width fill, spacing 30 ] <|
        List.map card [ "1", "3", "5", "8", "13" ]


viewPlayers : List Player -> Element Msg
viewPlayers playerList =
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
                        el
                            [ padding 10
                            , Font.alignRight
                            , Background.color UI.lightGrey
                            ]
                            (text <| Maybe.withDefault " " player.vote)
              }
            ]
        }


moderatorTools : Element Msg
moderatorTools =
    UI.actionButton
        [ centerX ]
        { isActive = True
        , onPress = Reset
        , label = text "Reset"
        }


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
