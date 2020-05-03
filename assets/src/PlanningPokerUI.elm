module PlanningPokerUI exposing (actionButton, blue, lightGrey, red, white)

import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input


blue : Element.Color
blue =
    Element.rgb255 100 100 255


lightGrey : Element.Color
lightGrey =
    Element.rgb255 200 200 200


red : Element.Color
red =
    Element.rgb255 255 100 100


white : Element.Color
white =
    Element.rgb255 255 255 255


actionButton :
    List (Element.Attribute msg)
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
        ([ Element.padding 20
         , Background.color color
         , Font.color white
         ]
            ++ attrs
        )
        { onPress = maybeEvent
        , label = label
        }
