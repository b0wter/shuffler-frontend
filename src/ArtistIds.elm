module ArtistIds exposing (..)

type ArtistId = ArtistId String


value : ArtistId -> String
value id = case id of ArtistId a -> a