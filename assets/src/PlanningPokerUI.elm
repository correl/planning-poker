module PlanningPokerUI exposing
    ( Theme(..)
    , actionButton
    , colors
    , fontSizes
    , heroText
    , navBar
    , onEnter
    , textInput
    , themePicker
    , toDocument
    )

import Browser exposing (Document)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html.Events
import Json.Decode as Decode


type Theme
    = Light
    | Dark


colors theme =
    let
        blue : Color
        blue =
            rgb255 100 100 255

        lightGrey : Color
        lightGrey =
            rgb255 200 200 200

        grey : Color
        grey =
            rgb255 50 50 50

        darkGrey : Color
        darkGrey =
            rgb255 20 20 20

        red : Color
        red =
            rgb255 255 100 100

        white : Color
        white =
            rgb255 255 255 255

        black : Color
        black =
            rgb255 0 0 0
    in
    case theme of
        Light ->
            { primary = blue
            , background = white
            , selected = blue
            , disabled = lightGrey
            , errorBackground = red
            , errorForeground = white
            , text = black
            , buttonText = white
            }

        Dark ->
            { primary = blue
            , background = darkGrey
            , selected = blue
            , disabled = grey
            , errorBackground = red
            , errorForeground = white
            , text = white
            , buttonText = lightGrey
            }


fontSizes =
    { huge = 80
    , big = 30
    , normal = 18
    }


textInput :
    Theme
    -> List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , label : Input.Label msg
        , placeholder : Maybe (Input.Placeholder msg)
        }
    -> Element msg
textInput theme attrs { onChange, text, label, placeholder } =
    Input.text
        (Font.color (colors theme).text
            :: Background.color (colors theme).background
            :: attrs
        )
        { onChange = onChange, text = text, label = label, placeholder = placeholder }


button :
    Theme
    -> List (Attribute msg)
    -> { isActive : Bool, onPress : msg, label : Element msg }
    -> Element msg
button theme attrs { isActive, onPress, label } =
    let
        ( color, maybeEvent ) =
            if isActive then
                ( (colors theme).primary, Just onPress )

            else
                ( (colors theme).disabled, Nothing )
    in
    Input.button
        (Background.color color
            :: Font.color (colors theme).buttonText
            :: attrs
        )
        { onPress = maybeEvent
        , label = label
        }


actionButton :
    Theme
    -> List (Attribute msg)
    -> { isActive : Bool, onPress : msg, label : Element msg }
    -> Element msg
actionButton theme attrs opts =
    button theme (padding 20 :: attrs) opts


heroText :
    List (Attribute msg)
    -> String
    -> Element msg
heroText attrs s =
    el ([ Font.size fontSizes.huge ] ++ attrs) (text s)


navBar : Theme -> List (Element msg) -> Element msg
navBar theme elements =
    row
        [ Background.color (colors theme).primary
        , Font.color (colors theme).buttonText
        , height (px 50)
        , width fill
        , padding 10
        ]
        elements


themePicker : Theme -> (Theme -> msg) -> Element msg
themePicker theme onChange =
    row []
        [ case theme of
            Light ->
                button theme
                    [ padding 5 ]
                    { isActive = True
                    , onPress = onChange Dark
                    , label = text "Dark mode 🌙"
                    }

            Dark ->
                button theme
                    [ padding 5 ]
                    { isActive = True
                    , onPress = onChange Light
                    , label = text "Light mode 🌞"
                    }
        ]


toDocument : Theme -> { title : String, body : List (Element msg) } -> Document msg
toDocument theme { title, body } =
    { title = title
    , body =
        [ layout
            [ Font.color (colors theme).text
            , Background.color (colors theme).background
            ]
          <|
            column [ width fill, height fill, spacing 20 ] body
        ]
    }


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field
                "key"
                Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )
