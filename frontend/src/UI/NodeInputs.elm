module UI.NodeInputs exposing
    ( NodeInputOptions
    , nodeCheckboxInput
    , nodeCounterWithReset
    , nodeNumberInput
    , nodeOnOffInput
    , nodeOptionInput
    , nodeTextInput
    , nodeTimeDateInput
    , nodeTimeInput
    )

import Api.Node exposing (Node)
import Api.Point as Point exposing (Point)
import Color
import Element exposing (..)
import Element.Input as Input
import Round
import Svg as S
import Svg.Attributes as Sa
import Time
import Time.Extra
import UI.Sanitize as Sanitize
import Utils.Time exposing (toLocal, toUTC)


type alias NodeInputOptions msg =
    { onEditNodePoint : List Point -> msg
    , node : Node
    , now : Time.Posix
    , zone : Time.Zone
    , labelWidth : Int
    }


nodeTextInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> Element msg
nodeTextInput o id index typ lbl =
    Input.text
        []
        { onChange =
            \d ->
                o.onEditNodePoint [ Point id index typ o.now 0 d 0 0 ]
        , text = Point.getText o.node.points id index typ
        , placeholder = Nothing
        , label = Input.labelLeft [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| lbl ++ ":"
        }


nodeTimeInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> Element msg
nodeTimeInput o id index typ lbl =
    let
        zoneOffset =
            Time.Extra.toOffset o.zone o.now

        current =
            Point.getText o.node.points id index typ

        display =
            case Sanitize.parseHM current of
                Just time ->
                    toLocal zoneOffset time

                Nothing ->
                    current
    in
    Input.text
        []
        { onChange =
            \d ->
                let
                    dClean =
                        Sanitize.time d

                    sendValue =
                        case Sanitize.parseHM dClean of
                            Just time ->
                                toUTC zoneOffset time

                            Nothing ->
                                d
                in
                o.onEditNodePoint [ Point id index typ o.now 0 sendValue 0 0 ]
        , text = display
        , placeholder = Nothing
        , label = Input.labelLeft [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| lbl ++ ":"
        }


nodeTimeDateInput : NodeInputOptions msg -> Int -> Element msg
nodeTimeDateInput o labelWidth =
    let
        zoneOffset =
            Time.Extra.toOffset o.zone o.now

        start =
            Point.getText o.node.points "" 0 Point.typeStart

        startDisplay =
            case Sanitize.parseHM start of
                Just time ->
                    toLocal zoneOffset time

                Nothing ->
                    start

        end =
            Point.getText o.node.points "" 0 Point.typeEnd

        endDisplay =
            case Sanitize.parseHM end of
                Just time ->
                    toLocal zoneOffset time

                Nothing ->
                    end

        send typ d =
            let
                dClean =
                    Sanitize.time d

                sendValue =
                    case Sanitize.parseHM dClean of
                        Just time ->
                            toUTC zoneOffset time

                        Nothing ->
                            d
            in
            o.onEditNodePoint [ Point "" 0 typ o.now 0 sendValue 0 0 ]

        weekdayCheckboxInput index label =
            column []
                [ el [ alignRight ] <| text label
                , nodeCheckboxInput o "" index Point.typeWeekday ""
                ]
    in
    column [ spacing 5 ]
        [ wrappedRow
            [ spacing 20
            , paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
            ]
            -- here, number matches Go Weekday definitions
            -- https://pkg.go.dev/time#Weekday
            [ el [ width <| px labelWidth ] none
            , weekdayCheckboxInput 0 "S"
            , weekdayCheckboxInput 1 "M"
            , weekdayCheckboxInput 2 "T"
            , weekdayCheckboxInput 3 "W"
            , weekdayCheckboxInput 4 "T"
            , weekdayCheckboxInput 5 "F"
            , weekdayCheckboxInput 6 "S"
            ]
        , Input.text
            []
            { onChange = send Point.typeStart
            , text = startDisplay
            , placeholder = Nothing
            , label = Input.labelLeft [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| "Start time:"
            }
        , Input.text
            []
            { onChange = send Point.typeEnd
            , text = endDisplay
            , placeholder = Nothing
            , label = Input.labelLeft [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| "End time:"
            }
        ]


nodeCheckboxInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> Element msg
nodeCheckboxInput o id index typ lbl =
    Input.checkbox
        []
        { onChange =
            \d ->
                let
                    v =
                        if d then
                            1.0

                        else
                            0.0
                in
                o.onEditNodePoint
                    [ Point id index typ o.now v "" 0 0 ]
        , checked =
            Point.getValue o.node.points id index typ == 1
        , icon = Input.defaultCheckbox
        , label =
            if lbl /= "" then
                Input.labelLeft [ width (px o.labelWidth) ] <|
                    el [ alignRight ] <|
                        text <|
                            lbl
                                ++ ":"

            else
                Input.labelHidden ""
        }


nodeNumberInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> Element msg
nodeNumberInput o id index typ lbl =
    let
        pMaybe =
            Point.get o.node.points id index typ

        currentValue =
            case pMaybe of
                Just p ->
                    if p.text /= "" then
                        if p.text == Point.blankMajicValue || p.text == "blank" then
                            ""

                        else
                            Sanitize.float p.text

                    else
                        String.fromFloat (Round.roundNum 6 p.value)

                Nothing ->
                    ""

        currentValueF =
            case pMaybe of
                Just p ->
                    p.value

                Nothing ->
                    0
    in
    Input.text
        []
        { onChange =
            \d ->
                let
                    dCheck =
                        if d == "" then
                            Point.blankMajicValue

                        else
                            case String.toFloat d of
                                Just _ ->
                                    d

                                Nothing ->
                                    currentValue

                    v =
                        if dCheck == Point.blankMajicValue then
                            0

                        else
                            Maybe.withDefault currentValueF <| String.toFloat dCheck
                in
                o.onEditNodePoint
                    [ Point id index typ o.now v dCheck 0 0 ]
        , text = currentValue
        , placeholder = Nothing
        , label = Input.labelLeft [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| lbl ++ ":"
        }


nodeOptionInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> List ( String, String )
    -> Element msg
nodeOptionInput o id index typ lbl options =
    Input.radio
        [ spacing 6 ]
        { onChange =
            \sel ->
                o.onEditNodePoint
                    [ Point id index typ o.now 0 sel 0 0 ]
        , label =
            Input.labelLeft [ padding 12, width (px o.labelWidth) ] <|
                el [ alignRight ] <|
                    text <|
                        lbl
                            ++ ":"
        , selected = Just <| Point.getText o.node.points id index typ
        , options =
            List.map
                (\opt ->
                    Input.option (Tuple.first opt) (text (Tuple.second opt))
                )
                options
        }


nodeCounterWithReset :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> String
    -> Element msg
nodeCounterWithReset o id index typ pointResetName lbl =
    let
        currentValue =
            Point.getValue o.node.points id index typ

        currentResetValue =
            Point.getValue o.node.points id index pointResetName /= 0
    in
    row [ spacing 20 ]
        [ el [ width (px o.labelWidth) ] <|
            el [ alignRight ] <|
                text <|
                    lbl
                        ++ ": "
                        ++ String.fromFloat currentValue
        , Input.checkbox []
            { onChange =
                \v ->
                    let
                        vFloat =
                            if v then
                                1.0

                            else
                                0
                    in
                    o.onEditNodePoint [ Point id index pointResetName o.now vFloat "" 0 0 ]
            , icon = Input.defaultCheckbox
            , checked = currentResetValue
            , label =
                Input.labelLeft [] (text "reset")
            }
        ]


nodeOnOffInput :
    NodeInputOptions msg
    -> String
    -> Int
    -> String
    -> String
    -> String
    -> Element msg
nodeOnOffInput o id index typ pointSetName lbl =
    let
        currentValue =
            Point.getValue o.node.points id index typ

        currentSetValue =
            Point.getValue o.node.points id index pointSetName

        fill =
            if currentSetValue == 0 then
                Color.rgb 0.5 0.5 0.5

            else
                Color.rgb255 50 100 150

        fillFade =
            if currentSetValue == 0 then
                Color.rgb 0.9 0.9 0.9

            else
                Color.rgb255 150 200 255

        fillFadeS =
            Color.toCssString fillFade

        fillS =
            Color.toCssString fill

        offset =
            if currentSetValue == 0 then
                3

            else
                3 + 24

        newValue =
            if currentSetValue == 0 then
                1

            else
                0
    in
    row [ spacing 10 ]
        [ el [ width (px o.labelWidth) ] <| el [ alignRight ] <| text <| lbl ++ ":"
        , Input.button
            []
            { onPress = Just <| o.onEditNodePoint [ Point id index pointSetName o.now newValue "" 0 0 ]
            , label =
                el [ width (px 100) ] <|
                    html <|
                        S.svg [ Sa.viewBox "0 0 48 24" ]
                            [ S.rect
                                [ Sa.x "0"
                                , Sa.y "0"
                                , Sa.width "48"
                                , Sa.height "24"
                                , Sa.ry "3"
                                , Sa.rx "3"
                                , Sa.fill fillS
                                ]
                              <|
                                if currentValue /= currentSetValue then
                                    [ S.animate
                                        [ Sa.attributeName "fill"
                                        , Sa.dur "2s"
                                        , Sa.repeatCount "indefinite"
                                        , Sa.values <|
                                            fillFadeS
                                                ++ ";"
                                                ++ fillS
                                                ++ ";"
                                                ++ fillFadeS
                                        ]
                                        []
                                    ]

                                else
                                    []
                            , S.rect
                                [ Sa.x (String.fromFloat offset)
                                , Sa.y "3"
                                , Sa.width "18"
                                , Sa.height "18"
                                , Sa.ry "3"
                                , Sa.rx "3"
                                , Sa.fill (Color.toCssString Color.white)
                                ]
                                []
                            ]
            }
        ]
