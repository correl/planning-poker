module PlanningPokerEntry exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import PlanningPokerAPI as API
import PlanningPokerUI as UI


type alias Model =
    { playerName : String
    , player : Maybe String
    , error : Maybe String
    }


type Msg
    = PlayerNameChanged String
    | CreateRoom
    | JoinedRoom String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { playerName = ""
      , player = Nothing
      , error = Nothing
      }
    , Cmd.none
    )


update : Nav.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
    case msg of
        PlayerNameChanged newName ->
            ( { model | playerName = newName }, Cmd.none )


        CreateRoom ->
            let
                room =
                    "a0fd1422-abd9-434e-9d7c-883294b2992c"
            in
            ( model
            , Cmd.batch
                [ API.joinRoom { room = room }
                , API.newProfile { playerName = model.playerName }
                ]
            )

        JoinedRoom room ->
            ( model, Nav.pushUrl key ("/room/" ++ room) )


view : Model -> Document Msg
view model =
    { title = "Planning Poker"
    , body = [ layout model ]
    }


layout : Model -> Html Msg
layout model =
    Element.layout [] <|
        column
            [ width fill, centerY, spacing 30 ]
            [ el [ centerX ] (text "Oh, hey!")
            , el [ centerX ] (text "Tell us who you are")
            , Input.text [ centerX, width (px 300) ]
                { onChange = PlayerNameChanged
                , text = model.playerName
                , label = Input.labelHidden "Your name"
                , placeholder = Just (Input.placeholder [] (text "Your name"))
                }
            , el [ centerX ] (text "then")
            , UI.actionButton [ centerX ]
                { isActive = not (String.isEmpty model.playerName)
                , onPress = CreateRoom
                , label = text "Make a room!"
                }
            , el
                [ centerX
                , Background.color UI.colors.errorBackground
                , padding 20
                , Font.color UI.colors.errorForeground
                , transparent (model.error == Nothing)
                ]
              <|
                text (Maybe.withDefault " " model.error)
            ]


subscriptions : Sub Msg
subscriptions =
    API.joinedRoom JoinedRoom
