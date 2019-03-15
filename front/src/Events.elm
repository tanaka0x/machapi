module Events exposing (..)

import Json.Decode as Decode
import Dict
import Set

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


type alias EventDate =
    { y: Int
    , m: Int
    , d: Int
    , original: String
    }


dateToString : EventDate -> String
dateToString evd =
    String.join "/" (List.map String.fromInt [evd.y, evd.m, evd.d])


compareDate : Maybe EventDate -> Maybe EventDate -> Order
compareDate lhs rhs =
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


type alias EventsByDate =
    List (String, List Event)


emptyDictByDate : Dict.Dict String (List Event)
emptyDictByDate = Dict.empty
    

updateDict : Event -> Maybe (List Event) -> Maybe (List Event)
updateDict ev ml =
    case ml of
        Just l -> Just (l ++ [ev])
        Nothing -> Just [ev]


toKey : Event -> String
toKey ev =
    case ev.date of
        Just d -> dateToString d
        Nothing -> "Unknown"


toKV : List Event -> List (String, Event)
toKV events = 
    List.map (\ev -> (toKey ev, ev)) events


byDate : List Event -> Dict.Dict String (List Event)
byDate events =
    let 
        kvl = toKV events
    in 
        List.foldl (\(k, v) result -> Dict.update k (updateDict v) result) emptyDictByDate kvl