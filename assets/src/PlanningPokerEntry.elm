module PlanningPokerEntry exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import PlanningPokerUI as UI


type alias Model =
    { playerName : String
    , roomName : String
    , player : Maybe String
    , error : Maybe String
    }


type Msg
    = PlayerNameChanged String
    | RoomNameChanged String
    | CreateRoom


init : () -> ( Model, Cmd Msg )
init _ =
    ( { playerName = ""
      , roomName = ""
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

        RoomNameChanged newName ->
            ( { model | roomName = newName }, Cmd.none )

        CreateRoom ->
            ( model, Nav.pushUrl key "/room/a0fd1422-abd9-434e-9d7c-883294b2992c" )


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
            , el [ centerX ] (text "and what you're up to")
            , Input.text [ centerX, width (px 300) ]
                { onChange = RoomNameChanged
                , text = model.roomName
                , label = Input.labelHidden "Room name"
                , placeholder = Just (Input.placeholder [] (text "Planning Poker"))
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
