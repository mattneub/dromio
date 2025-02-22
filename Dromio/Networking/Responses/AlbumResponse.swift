import Foundation

/// Inner response for the `getAlbum` request, which provides the album along with its songs.
struct AlbumResponse: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let album: SubsonicAlbum // includes songs
    let error: SubsonicError? // may not be possible, but present for parity with ping
}
