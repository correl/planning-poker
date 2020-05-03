module PlanningPokerEntry exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)


type User
    = Moderator { name : String }


type alias Model =
    { name : String
    , user : Maybe User
    , error : Maybe String
    }


type Msg
    = NameChanged String
    | CreateRoom


init : () -> ( Model, Cmd Msg )
init _ =
    ( { name = ""
      , user = Nothing
      , error = Nothing
      }
    , Cmd.none
    )


update : Nav.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
    case msg of
        NameChanged newName ->
            ( { model | name = newName }, Cmd.none )

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
                { onChange = NameChanged
                , text = model.name
                , label = Input.labelHidden "Your name"
                , placeholder = Just (Input.placeholder [] (text "Your name"))
                }
            , el [ centerX ] (text "then")
            , let
                ready =
                    not (String.isEmpty model.name)

                ( color, event ) =
                    if ready then
                        ( blue, Just CreateRoom )

                    else
                        ( lightGrey, Nothing )
              in
              Input.button
                [ centerX
                , padding 20
                , Background.color color
                , Font.color white
                ]
                { onPress = event
                , label = text "Make a room!"
                }
            , el
                [ centerX
                , Background.color red
                , padding 20
                , Font.color white
                , transparent (model.error == Nothing)
                ]
              <|
                text (Maybe.withDefault " " model.error)
            ]


blue =
    rgb255 100 100 255


red =
    rgb255 255 100 100


white =
    rgb255 255 255 255


lightGrey =
    rgb255 200 200 200
