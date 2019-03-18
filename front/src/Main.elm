module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img, a, input, span, label)
import Html.Attributes exposing (src, class, href, id, value)
import Html.Events exposing (onInput)
import Http
import Json.Decode as Decode
import Events exposing (Event, EventDate, eventDecoder, eventDateDecoder, compareDate)
import Dict


---- MODEL ----


type alias Model =
    { events : List ((Int, Int, Int), List Event)
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
    let 
        filtered = 
            List.map (\(date, events) -> (date, filterEvents model.query events)) model.events
            |> List.filter (\(date, events) -> not <| List.isEmpty events)
    in 
        div []
            [ div [ class "" ]
                [ div [ class "top container" ] [ h1 [] [ text "近日のイベント一覧" ] ]
                , div [ class "query container"] 
                    [ div [ class "field" ] 
                        [ label [ class "label" ] [ text "検索" ]
                        , div [ class "control" ]
                            [ input [ class "input", onInput SetQuery, value model.query ] [] ]
                        ]
                    ]
                , if List.isEmpty filtered
                    then
                        div [ class "empty-events container"] [ text "イベントが見つかりませんでした" ]
                    else
                        renderEvents filtered
                ]
            ]


defaultString : (a -> String) -> Maybe a -> String
defaultString toString v =
    case v of
        Nothing -> ""
        Just item -> toString item


dateToString : (Int, Int, Int) -> String
dateToString date =
    case date of
        (0, 0, 0) -> "Unknown"
        (y, m, d) -> Events.dateToString { y = y, m = m, d = d, original = "" }


filterEvents : String -> List Event -> List Event
filterEvents query events = 
    if String.isEmpty query
        then events
        else List.filter (\ev -> String.contains query ev.title) events


renderEvents : List ((Int, Int, Int), List Event) -> Html msg
renderEvents dateEvents =
    div [ class "events container" ] 
        <| List.map 
            (\(date, events) -> renderByDate date events)
            dateEvents


renderByDate : (Int, Int, Int) -> List Event -> Html msg
renderByDate date events =
    let ds = dateToString date
    in div [ class "at", id ds ]
        <| [ div [ class "date" ] [ text ds ] ] ++ 
            List.map (renderEvent date) events


renderEvent : (Int, Int, Int) -> Event -> Html msg
renderEvent date ev =
    div [ class "event" ]
        [ div [ class "name" ]
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
