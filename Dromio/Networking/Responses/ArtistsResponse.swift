import Foundation

struct ArtistsResponse: InnerResponse { // for getArtists
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let artists: ArtistsIndex
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

struct ArtistsIndex: Codable, Equatable {
    let index: [ArtistIndex]
}

struct ArtistIndex: Codable, Equatable {
    let artist: [SubsonicArtist]
}

struct ArtistResponse: InnerResponse { // for getArtist
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let artist: SubsonicArtist
    let error: SubsonicError? // may not be possible, but present for parity with ping
}
