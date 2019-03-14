module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img, a)
import Html.Attributes exposing (src, class, href)
import Http
import Json.Decode as Decode

---- MODEL ----


type alias Model =
    { events: List Event
    , error: Maybe Http.Error
    }


type alias EventDate =
    { y: Int
    , m: Int
    , d: Int
    , original: String
    }

toString : EventDate -> String
toString evd =
    String.join "/" (List.map String.fromInt [evd.y, evd.m, evd.d])

compare : Maybe EventDate -> Maybe EventDate -> Order
compare lhs rhs =
    case (lhs, rhs) of
        (Just l, Just r) ->
            case l.y == r.y of
                True -> 
                    case l.m == r.m of
                        True ->
                            case l.d == r.d of
                                True -> EQ
                                _ -> 
                                    if l.d < r.d
                                        then LT
                                        else GT
                        _ ->
                            if l.m < r.m
                                then LT
                                else GT
                _ -> 
                    if l.y < r.y 
                        then LT
                        else GT
        (Nothing, Just r) ->
            GT
        (Just l, Nothing) ->
            LT
        _ ->
            EQ


eventDateDecoder =
    Decode.map4 EventDate
        (Decode.field "y" Decode.int)
        (Decode.field "m" Decode.int)
        (Decode.field "d" Decode.int)
        (Decode.field "original" Decode.string)


type alias Event =
    { site : String
    , title : String
    , href : String
    , date : Maybe EventDate
    }

eventDecoder =
    Decode.map4 Event
        (Decode.field "site" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "href" Decode.string)
        (Decode.field "date" (Decode.nullable eventDateDecoder))

requestEvents : Cmd Msg
requestEvents = 
    Http.get 
        { url = "/events"
        , expect = Http.expectJson ReceiveEvents (Decode.list eventDecoder)
        }

init : ( Model, Cmd Msg )
init =
    ( { events = [], error = Nothing }, requestEvents )



---- UPDATE ----


type Msg
    = NoOp
    | ReceiveEvents (Result Http.Error (List Event))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveEvents res ->
            case res of
                Ok events ->
                    ( { model | events = List.sortWith (\l r -> compare l.date r.date) events }, Cmd.none )
                Err e ->
                    ( { model | error = Just e }, Cmd.none )
        _ -> ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , div [ class "events" ] 
            (List.map renderEvent model.events)
        ]


defaultString : Maybe EventDate -> String
defaultString v =
    case v of
        Nothing -> ""
        Just item -> toString item

renderEvent : Event -> Html msg
renderEvent ev =
    div [ class "event" ]
        [ div [ class "title" ]
            [ a [ href ev.href ] [ text ev.title ] ]
        , div [ class "detail" ]
            [ text <| defaultString ev.date ]
        ]

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
