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


type alias Model =
    { name : String
    , player : String
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


type Msg
    = Vote String
    | Reset


init : () -> ( Model, Cmd Msg )
init _ =
    ( { name = "Planning Poker"
      , player = "099b73da-e714-4085-aa33-6419076d0765"
      , players =
            Dict.fromList
                [ ( "099b73da-e714-4085-aa33-6419076d0765"
                  , { level = Moderator, name = "Me", vote = Nothing }
                  )
                , ( "44db0a59-28bb-4b9f-8e5d-a46f2c2a3266"
                  , { level = Participant, name = "John", vote = Nothing }
                  )
                , ( "69b8b450-bc2a-4eeb-b056-91c7aa4ba528"
                  , { level = Participant, name = "Jane", vote = Nothing }
                  )
                ]
      }
    , Cmd.none
    )


update : Nav.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
    case msg of
        Vote value ->
            ( { model
                | players =
                    Dict.update
                        model.player
                        (Maybe.map (\p -> { p | vote = Just value }))
                        model.players
              }
            , Cmd.none
            )

        Reset ->
            ( { model
                | players =
                    Dict.map
                        (\k v -> { v | vote = Nothing })
                        model.players
              }
            , Cmd.none
            )


view : Model -> Document Msg
view model =
    { title = model.name
    , body = [ layout model ]
    }


layout : Model -> Html Msg
layout model =
    let
        myVote =
            Dict.get model.player model.players
                |> Maybe.andThen .vote
    in
    Element.layout [] <|
        column [ width fill, spacing 20 ]
            [ navBar model
            , row
                [ width fill ]
                [ el [ width (fillPortion 3), alignTop ] <|
                    cards myVote
                , el [ width (fillPortion 1), alignTop ] <|
                    players (Dict.values model.players)
                ]
            , moderatorTools
            ]


navBar : Model -> Element Msg
navBar model =
    let
        myName =
            Dict.get model.player model.players
                |> Maybe.map .name
                |> Maybe.withDefault ""
    in
    row
        [ Background.color blue
        , height (px 50)
        , width fill
        , padding 10
        ]
        [ el
            [ Font.alignLeft
            , Font.color white
            , width fill
            ]
            (text model.name)
        , el
            [ Font.alignRight
            , Font.color white
            ]
            (text myName)
        ]


cards : Maybe String -> Element Msg
cards selected =
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
                        blue

                    else
                        white
                , Font.size 50
                ]
                { onPress = Just (Vote value)
                , label = el [ centerX, centerY ] (text value)
                }
    in
    row [ width fill, spacing 30 ] <|
        List.map card [ "1", "3", "5", "8", "13" ]


players : List Player -> Element Msg
players playerList =
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
                            , Background.color lightGrey
                            ]
                            (text <| Maybe.withDefault " " player.vote)
              }
            ]
        }


moderatorTools : Element Msg
moderatorTools =
    Input.button
        [ centerX
        , padding 20
        , Background.color blue
        , Font.color white
        ]
        { onPress = Just Reset
        , label = text "Reset"
        }


blue =
    rgb255 100 100 255


lightGrey =
    rgb255 200 200 200


white =
    rgb255 255 255 255
