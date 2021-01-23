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
    { theme : UI.Theme
    , room : String
    , playerName : String
    , player : Maybe String
    , error : Maybe String
    }


type Msg
    = PlayerNameChanged String
    | UpdateTheme UI.Theme
    | CreateRoom


init : UI.Theme -> String -> ( Model, Cmd Msg )
init theme room =
    ( { theme = theme
      , room = room
      , playerName = ""
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
            if not (String.isEmpty model.playerName) then
                ( model, Nav.pushUrl key ("/room/" ++ model.room) )

            else
                ( model, Cmd.none )

        UpdateTheme theme ->
            ( { model | theme = theme }, API.updateTheme theme )


view : Model -> Document Msg
view model =
    UI.toDocument model.theme
        { title = "Planning Poker"
        , body = [ layout model ]
        }


layout : Model -> Element Msg
layout model =
    column [ width fill, height fill, centerY ]
        [ column
            [ width fill, centerY, spacing 30 ]
            [ el [ centerX ] (text "Oh, hey!")
            , el [ centerX ] (text "Tell us who you are")
            , UI.textInput model.theme
                [ centerX, width (px 300), UI.onEnter CreateRoom ]
                { onChange = PlayerNameChanged
                , text = model.playerName
                , label = Input.labelHidden "Your name"
                , placeholder = Just (Input.placeholder [] (text "Your name"))
                }
            , el [ centerX ] (text "then")
            , UI.actionButton model.theme
                [ centerX ]
                { isActive = not (String.isEmpty model.playerName)
                , onPress = CreateRoom
                , label = text "Make a room!"
                }
            , el
                [ centerX
                , Background.color (UI.colors model.theme).errorBackground
                , padding 20
                , Font.color (UI.colors model.theme).errorForeground
                , transparent (model.error == Nothing)
                ]
              <|
                text (Maybe.withDefault " " model.error)
            ]
        , column [] [ UI.themePicker model.theme UpdateTheme ]
        ]
