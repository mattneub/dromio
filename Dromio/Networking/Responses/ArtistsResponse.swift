import Foundation

struct ArtistsResponse: InnerResponse {
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
