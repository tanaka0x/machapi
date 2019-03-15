module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img, a, input)
import Html.Attributes exposing (src, class, href, id, value)
import Html.Events exposing (onInput)
import Http
import Json.Decode as Decode
import Events exposing (Event, EventDate, eventDecoder, eventDateDecoder, dateToString, compareDate)
import Dict


---- MODEL ----


type alias Model =
    { events : List (String, List Event)
    , query : String
    , error : Maybe Http.Error
    }


requestEvents : Cmd Msg
requestEvents = 
    Http.get 
        { url = "/events"
        , expect = Http.expectJson ReceiveEvents (Decode.list eventDecoder)
        }

init : ( Model, Cmd Msg )
init =
    ( { events = []
    , error = Nothing 
    , query = ""
    }
    , requestEvents 
    )



---- UPDATE ----


type Msg
    = NoOp
    | ReceiveEvents (Result Http.Error (List Event))
    | SetQuery String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveEvents res ->
            case res of
                Ok events ->
                    ( { model | events = Events.byDate events |> Dict.toList }, Cmd.none )
                Err e ->
                    ( { model | error = Just e }, Cmd.none )
        
        SetQuery newQuery ->
            ( { model | query = newQuery }, Cmd.none )
        
        _ -> ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "近日のイベント一覧" ]
        , div [ class "query" ]
            [ input [ onInput SetQuery, value model.query ] [] ]
        , renderEvents model.query model.events
        ]


defaultString : (a -> String) -> Maybe a -> String
defaultString toString v =
    case v of
        Nothing -> ""
        Just item -> toString item


filterEvents : String -> List Event -> List Event
filterEvents query events = 
    if String.isEmpty query
        then events
        else List.filter (\ev -> String.contains query ev.title) events


renderEvents : String -> List (String, List Event) -> Html msg
renderEvents query dateEvents =
    div [ class "events" ] 
        <| List.map 
            (\(date, events) -> renderByDate query date events)
            dateEvents


renderByDate : String -> String -> List Event -> Html msg
renderByDate query date events =
    div [ class "at", id date ]
        <| [ div [ class "date" ] [ text date] ] ++ 
            List.map (renderEvent date) (filterEvents query events)


renderEvent : String -> Event -> Html msg
renderEvent date ev =
    div [ class "event" ]
        [ div [ class "title" ]
            [ a [ href ev.href ] [ text ev.title ] ]
        , div [ class "detail" ]
            []
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
