module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html
import PlanningPokerEntry as Entry
import PlanningPokerNotFound as NotFound
import PlanningPokerRoom as Room
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s, string)


type alias Flags =
    { player : String
    , room : String
    }


type alias Model =
    { page : Page
    , key : Nav.Key
    , player : String
    , room : String
    }


type Page
    = EntryPage Entry.Model
    | RoomPage Room.Model
    | NotFound


type Route
    = Entry
    | Room String


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | EntryMsg Entry.Msg
    | RoomMsg Room.Msg


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init { player, room } url key =
    updateUrl url
        { page = NotFound
        , key = key
        , player = player
        , room = room
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ClickedLink urlRequest, _ ) ->
            ( model, Cmd.none )

        ( ChangedUrl url, _ ) ->
            updateUrl url model

        ( EntryMsg entryMsg, EntryPage entryModel ) ->
            toEntry model (Entry.update model.key entryMsg entryModel)

        ( RoomMsg roomMsg, RoomPage roomModel ) ->
            toRoom model (Room.update model.key roomMsg roomModel)

        _ ->
            ( model, Cmd.none )


toEntry : Model -> ( Entry.Model, Cmd Entry.Msg ) -> ( Model, Cmd Msg )
toEntry model ( entryModel, entryCmd ) =
    ( { model | page = EntryPage entryModel }
    , Cmd.map EntryMsg entryCmd
    )


toRoom : Model -> ( Room.Model, Cmd Room.Msg ) -> ( Model, Cmd Msg )
toRoom model ( roomModel, roomCmd ) =
    ( { model | page = RoomPage roomModel }
    , Cmd.map RoomMsg roomCmd
    )


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Parser.parse parser url of
        Just Entry ->
            toEntry model (Entry.init model.room)

        Just (Room id) ->
            case model.page of
                EntryPage entryModel ->
                    toRoom model
                        (Room.init
                            { id = id
                            , player = model.player
                            , roomName = "Planning Poker"
                            , playerName = entryModel.playerName
                            }
                        )

                _ ->
                    toRoom model
                        (Room.init
                            { id = id
                            , player = model.player
                            , roomName = "Planning Poker"
                            , playerName = ""
                            }
                        )

        Nothing ->
            ( model, Cmd.none )


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Entry Parser.top
        , Parser.map Room (s "room" </> string)
        ]


view : Model -> Document Msg
view model =
    let
        mapDocument toMsg { title, body } =
            { title = title, body = List.map (Html.map toMsg) body }
    in
    case model.page of
        EntryPage entryModel ->
            mapDocument EntryMsg <| Entry.view entryModel

        RoomPage roomModel ->
            mapDocument RoomMsg <| Room.view roomModel

        NotFound ->
            NotFound.view


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Sub.map RoomMsg Room.subscriptions
        ]
