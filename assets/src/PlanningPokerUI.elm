module PlanningPokerUI exposing
    ( actionButton
    , blue
    , colors
    , fontSizes
    , heroText
    , lightGrey
    , red
    , toDocument
    , white
    )

import Browser exposing (Document)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input


colors =
    let
        primary =
            blue
    in
    { primary = primary
    , background = white
    , selected = primary
    , disabled = lightGrey
    , error = red
    }


fontSizes =
    { huge = 80
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
        [ layout [ explain Debug.todo ] <|
            column [ width fill, height fill, spacing 20 ] body
        ]
    }
