module PlanningPokerUI exposing
    ( actionButton
    , colors
    , fontSizes
    , heroText
    , onEnter
    , toDocument
    )

import Browser exposing (Document)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html.Events
import Json.Decode as Decode


colors =
    let
        primary =
            blue
    in
    { primary = primary
    , background = white
    , selected = primary
    , disabled = lightGrey
    , errorBackground = red
    , errorForeground = white
    , text = black
    , buttonText = white
    }


fontSizes =
    { huge = 80
    , big = 30
    , normal = 18
    }


blue : Color
blue =
    rgb255 100 100 255


lightGrey : Color
lightGrey =
    rgb255 200 200 200


red : Color
red =
    rgb255 255 100 100


white : Color
white =
    rgb255 255 255 255


black : Color
black =
    rgb255 0 0 0


actionButton :
    List (Attribute msg)
    -> { isActive : Bool, onPress : msg, label : Element msg }
    -> Element msg
actionButton attrs { isActive, onPress, label } =
    let
        ( color, maybeEvent ) =
            if isActive then
                ( blue, Just onPress )

            else
                ( lightGrey, Nothing )
    in
    Input.button
        ([ padding 20
         , Background.color color
         , Font.color white
         ]
            ++ attrs
        )
        { onPress = maybeEvent
        , label = label
        }


heroText :
    List (Attribute msg)
    -> String
    -> Element msg
heroText attrs s =
    el ([ Font.size fontSizes.huge ] ++ attrs) (text s)


toDocument : { title : String, body : List (Element msg) } -> Document msg
toDocument { title, body } =
    { title = title
    , body =
        [ layout [] <|
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
