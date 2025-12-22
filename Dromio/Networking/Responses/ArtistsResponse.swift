import Foundation

/// Inner response for the `getArtists` request.
struct ArtistsResponse: @MainActor InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let artists: ArtistsIndex
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

/// The type of the ArtistsResponse `artists`.
struct ArtistsIndex: Codable, Equatable {
    let index: [ArtistIndex]
}

/// The type of the ArtistsIndex `index`.
struct ArtistIndex: Codable, Equatable {
    let artist: [SubsonicArtist]
}
