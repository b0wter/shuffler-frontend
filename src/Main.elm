port module Main exposing (..)

import Browser
import Debug
import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (..)
import Regex
import Random
import Random.Extra
import Html.Events exposing (onClick)
import Random.List
import Array exposing(Array)
import Albums exposing(Album, CoverImage)
import AlbumStorage exposing(albumStorage)
import List.Extra as List


type alias Flags =
    {}


type alias Model =
    { blacklistedAlbums : List String
    , albums: Array Album
    , current: Int
    }


type alias AlbumArt =
    { url : String
    , height : Int
    , width : Int
    }


port cookieReceiver : (String -> msg) -> Sub msg


port fetchCookies : () -> Cmd msg


port setCookie : String -> Cmd msg


port changeAlbum : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    cookieReceiver GotCookie


emptyModel : Model
emptyModel =
    { blacklistedAlbums = []
    , albums = AlbumStorage.albumStorage
    , current = 0
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


type Msg
    = Reset
    | GotCookie String
    | NextAlbum
    | PreviousAlbum
    | AlbumsShuffled (List Album)


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( emptyModel, Cmd.batch [ fetchCookies (), albumStorage |> startShuffleAlbums ] )


deconstructCookie : String -> List String
deconstructCookie content =
    []


constructCookie : List String -> String
constructCookie albums =
    ""


modelToCookie : Model -> String
modelToCookie model =
    constructCookie model.blacklistedAlbums


updateModelFromCookie : String -> Model -> Model
updateModelFromCookie content model =
    let
        albumsToBlacklist =
            deconstructCookie content
    in
    { model | blacklistedAlbums = albumsToBlacklist }


startShuffleAlbums : Array Album -> Cmd Msg
startShuffleAlbums albums =
    let
        generator = Random.List.shuffle (albums |> Array.toList)
    in
        generator |> Random.generate AlbumsShuffled 


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset ->
            ( emptyModel, setCookie (emptyModel |> modelToCookie) )

        GotCookie text ->
            let
                albumsToBlacklist =
                    text |> deconstructCookie
            in
            ( { model | blacklistedAlbums = albumsToBlacklist }, Cmd.none )

        NextAlbum ->
            let
                newModel = { model | current = modBy (model.albums |> Array.length) (model.current + 1) }
            in
            ( newModel, Cmd.none )

        PreviousAlbum ->
            let
                newModel = { model | current = modBy (model.albums |> Array.length) (model.current - 1) }
            in
            ( newModel, Cmd.none )

        AlbumsShuffled albums ->
            ({ model | albums = albums |> Array.fromList }, Cmd.none)


tryAlbumNumberFrom : String -> Maybe Int
tryAlbumNumberFrom input =
    let
        albumNumber =
            Maybe.withDefault Regex.never <| Regex.fromString "\\d\\d\\d"
    in
    Regex.find albumNumber input
        |> List.head
        |> Maybe.map (\match -> match.match)
        |> Maybe.andThen String.toInt


view : Model -> Html Msg
view model =
    case model.albums |> Array.get model.current of
        Nothing ->
            div [] [ text "no album :(" ]

        Just album ->
            let
                largestCover = album.covers |> List.maximumBy (\a -> a.width) |> Maybe.withDefault { width = 640, height = 640, url = "https://fakeimg.pl/640x640" }
                coverMaxWidth =
                    "min(80vw, " ++ (largestCover.width |> String.fromInt) ++ "px)"

                coverMaxHeight =
                    "min(60vh, 90vw, " ++ (largestCover.width |> String.fromInt) ++ "px)"

                boxShadowSize =
                    "75px"

                backgroundImageUrl =
                    largestCover.url

                coverSourceSet =
                    backgroundImageUrl ++ " " ++ (largestCover.width |> String.fromInt) ++ "w"

                coverAspectRatio =
                    (largestCover.width |> toFloat) / (largestCover.height |> toFloat)

                albumNumber =
                    album.name |> tryAlbumNumberFrom |> Maybe.withDefault 0

                coverCenterX =
                    if albumNumber >= 126 then
                        (60 |> String.fromInt) ++ "%"
                    else
                        (50 |> String.fromInt) ++ "%"

                coverCenterY =
                    (50 |> String.fromInt) ++ "%"

                githubLink =
                    Html.a [ class "mr-05 p-15", href "https://github.com/b0wter/shuffler" ] [ img [ class "social-button", src "img/github.svg", alt "Link to GitHub" ] [] ]

                xLink =
                    Html.a [ class "ml-05 p-15", href "https://x.com/b0wter" ] [ img [ class "social-button", src "img/x.svg", alt "Link to X" ] [] ]

                backgroundFadeDuration = "5000ms"
                backgroundFadeEase = "3000ms"
            in
            div
                [ id "background-image-container"
                , style "background-image" ("url(" ++ backgroundImageUrl ++ ")")
                , style "background-position" (coverCenterX ++ " " ++ coverCenterY)
                ]
                [ div
                    [ id "background-color-overlay"
                    , style "-webkit-transition"    ("background " ++ backgroundFadeDuration ++ " linear")
                    , style "-moz-transition"       ("background " ++ backgroundFadeDuration ++ " linear")
                    , style "-o-transition"         ("background " ++ backgroundFadeDuration ++ " linear")
                    , style "transition"            ("background " ++ backgroundFadeDuration ++ " linear")
                    ]
                    [ div
                        [ id "inner-layout-container"
                        , class "d-flex flex-column"
                        , style "height" "100svh"
                        ]
                        [ div
                            [ id "social-links-container" ]
                            [ div
                                [ class "d-flex justify-content-center align-items-center" ]
                                [ githubLink, xLink ]
                            ]
                        , div
                            [ style "flex-grow" "1"
                            , style "width" coverMaxWidth
                            , style "max-height" coverMaxHeight
                            ]
                            [ div
                                [ id "cover-container", class "", style "width" coverMaxWidth, style "position" "relative", style "height" "100%" ]
                                [ img
                                    [ id "cover-img"
                                    , attribute "srcset" coverSourceSet
                                    , style "position" "absolute"
                                    , style "top" "0"
                                    , style "bottom" "0"
                                    , style "width" coverMaxWidth
                                    , style "z-index" "1"
                                    ]
                                    []
                                , div
                                    [ id "cover-glow"
                                    , style "max-width" coverMaxWidth
                                    , style "aspect-ratio" (coverAspectRatio |> String.fromFloat)
                                    , style "max-height" coverMaxWidth
                                    , style "box-shadow" (boxShadowSize ++ " " ++ boxShadowSize ++ " " ++ boxShadowSize)
                                    , style "border-radius" "20.02px"
                                    , style "filter" "blur(7.5vw)"
                                    ]
                                    []
                                ]
                            , div [ id "cover-text", style "display" "none" ] [ text album.name ]
                            ]
                        , div
                            [ class "d-flex align-items-center justify-content-center"
                            , style "z-index" "1"
                            ]
                            [ a [ href "#", onClick PreviousAlbum ] [ img [ style "padding" "1.5rem", style "height" "25px", style "width" "25px", style "transform" "scaleX(-1)", src "img/next.svg" ] [] ]
                            , a [ href album.urlToOpen ] [ img [ style "height" "10rem", src "img/play.svg", alt "play current album on Spotify" ] [] ]
                            , a [ href "#", onClick NextAlbum ] [ img [ class "p-15", src "img/next.svg", alt "get next suggestion" ] [] ]
                            ]
                        , div
                            [ style "text-decoration" "none", style "color" "white" ]
                            [ div []
                                [ div
                                    [ style "font-family" "urbanist, sans-serif", style "font-weight" "1000", style "height" "4rem", style "text-transform" "uppercase", class "d-flex justify-content-center align-items-center" ]
                                    [ a
                                        [ href ("block/" ++ album.id), class "z-2 small-text non-styled-link d-flex align-items-center mr-10" ]
                                        [ img [ style "height" "2rem", class "mr-05", src "img/block.svg", alt "block current album" ] [], div [] [ text "block" ] ]
                                    , a
                                        [ href "clearAll", class "z-2 small-text non-styled-link d-flex align-items-center ml-10" ]
                                        [ img [ style "height" "2rem", class "mr-05", src "img/clear-format-white.svg", alt "clear album blacklist" ] [], div [] [ text "clear blocked" ] ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
