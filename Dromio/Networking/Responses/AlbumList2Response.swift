import Foundation

/// Inner response for the `getAlbumList2` request.
struct AlbumList2Response: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let albumList2: AlbumsResponse
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

/// Type of the `albumList2` property of the AlbumList2Response.
struct AlbumsResponse: Codable {
    let album: [SubsonicAlbum]
}
