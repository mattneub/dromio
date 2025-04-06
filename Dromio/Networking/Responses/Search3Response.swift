import Foundation

/// Inner response for the `search3` request.
struct Search3Response: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let searchResult3: SearchResult
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

/// Type of the `searchResult3` property of the Search3Response.
struct SearchResult: Codable, Equatable {
    let artist: [SubsonicArtist]?
    let album: [SubsonicAlbum]?
    let song: [SubsonicSong]?
}
