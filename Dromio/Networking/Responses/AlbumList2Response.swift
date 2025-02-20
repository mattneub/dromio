import Foundation

struct AlbumList2Response: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let albumList2: AlbumsResponse
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

struct AlbumsResponse: Codable {
    let album: [SubsonicAlbum]
}

struct SubsonicAlbum: Codable, Equatable {
    let id: String
    let name: String
    let songCount: Int
}
