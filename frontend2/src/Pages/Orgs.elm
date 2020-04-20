module Pages.Orgs exposing (Model, Msg, page)

import Device
import Dict exposing (Dict)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Generated.Params as Params
import Global
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Org as O
import Spa.Page
import Spa.Types as Types
import Url.Builder as Url
import User
import Utils.Spa exposing (Page)
import Utils.Styles exposing (palette, size)


page : Page Params.Orgs Model Msg model msg appMsg
page =
    Spa.Page.component
        { title = always "Orgs"
        , init = init
        , update = always update
        , subscriptions = always subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { error : Maybe Http.Error
    , emails : Dict String String
    }


init : Types.PageContext route Global.Model -> Params.Orgs -> ( Model, Cmd Msg, Cmd Global.Msg )
init context _ =
    ( empty
    , Cmd.none
    , Spa.Page.send <| Global.RequestOrgs
    )



empty =
    { error = Nothing
    , emails = Dict.empty
    }



-- UPDATE


type Msg
    = EditEmail String String
    | EditRole String Bool


update : Msg -> Model -> ( Model, Cmd Msg, Cmd Global.Msg )
update msg model =
    case msg of
        EditEmail id email ->
            ( { model | emails = Dict.insert id email model.emails }
            , Cmd.none
            , Cmd.none
              -- TODO: does this user exist?
            )

        _ ->
            ( model
            , Cmd.none
            , Cmd.none
            )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Types.PageContext route Global.Model -> Model -> Element Msg
view context model =
    column
        [ width fill, spacing 32 ]
        [ el [ padding 16, Font.size 24 ] <| text "Orgs"
        , viewError model.error
        , case context.global of
            Global.SignedIn sess ->
                viewOrgs model.emails sess.data.orgs

            _ ->
                el [ padding 16 ] <| text "Sign in to view your orgs."
        ]


viewOrgs emails orgs =
    column
        [ width fill
        , spacing 40
        ]
    <|
        List.map (viewOrg emails) orgs


getEmail emails orgId =
    case Dict.get orgId emails of
        Just email ->
            email

        Nothing ->
            ""


viewOrg : Dict String String -> O.Org -> Element Msg
viewOrg emails org =
    column
        [ width fill
        , Border.widthEach { top = 2, bottom = 0, left = 0, right = 0 }
        , Border.color palette.black
        , spacing 6
        ]
        [ viewOrgName org.name
        , viewItems (getEmail emails org.id) org
        ]


viewItems email org =
    wrappedRow
        [ width fill
        , spacing 16
        ]
        [ viewUsers email org
        , viewDevices org.devices
        ]


viewUsers : String -> O.Org -> Element Msg
viewUsers email org =
    column
        []
        [ Input.text
            []
            { onChange = EditEmail org.id
            , text = email
            , placeholder = Nothing
            , label = label Input.labelAbove "Add user by email address"
            }
        , viewList "Users" viewUser org.users
        ]


label kind =
    kind
        [ padding 16
        , Font.italic
        , Font.color palette.gray
        ]
        << text


viewDevices =
    viewList "Devices" viewDevice


viewOrgName name =
    el
        [ padding 16
        , size.heading
        ]
    <|
        text name


viewList name fn list =
    column
        [ alignTop
        , width (fill |> minimum 250)
        , spacing 16
        ]
    <|
        [ el [ padding 16 ] <| text name ]
            ++ List.map fn list


viewItem =
    wrappedRow
        [ padding 16
        , spacing 25
        , Border.widthEach { top = 1, bottom = 0, left = 0, right = 0 }
        , Border.color palette.black
        , width fill
        ]


viewUser : User.User -> Element Msg
viewUser user =
    viewItem
        [ text user.first
        , text user.last
        , viewRole
            { role = "user"
            , value = True
            , action = EditRole
            }
        , viewRole
            { role = "admin"
            , value = True
            , action = EditRole
            }
        ]


hasRole role user =
    List.member role <| List.map .description user.roles


viewRole { role, value, action } =
    Input.checkbox
        [ padding 16 ]
        { checked = value
        , icon = Input.defaultCheckbox
        , label = label Input.labelRight role
        , onChange = action role
        }


viewDevice : Device.Device -> Element Msg
viewDevice device =
    viewItem
        [ text device.id
        , text device.config.description
        ]


viewError error =
    case error of
        Just (Http.BadUrl str) ->
            text <| "bad URL: " ++ str

        Just Http.Timeout ->
            text "timeout"

        Just Http.NetworkError ->
            text "network error"

        Just (Http.BadStatus status) ->
            text <| "bad status: " ++ String.fromInt status

        Just (Http.BadBody str) ->
            text <| "bad body: " ++ str

        Nothing ->
            none
