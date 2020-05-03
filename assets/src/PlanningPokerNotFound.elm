module PlanningPokerNotFound exposing (view)

import Browser exposing (Document)
import Element exposing (..)
import Html exposing (Html)


view : Document msg
view =
    { title = "Planning Poker - Page Not Found"
    , body = []
    }


layout : Html msg
layout =
    Element.layout [] <|
        text "404 Not Found"
