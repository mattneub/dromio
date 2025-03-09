import Foundation

struct SearchResult3Response: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let searchResult3: SearchResult
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

struct SearchResult: Codable, Equatable {
    let artist: [SubsonicArtist]?
    let album: [SubsonicAlbum]?
    let song: [SubsonicSong]?
}
