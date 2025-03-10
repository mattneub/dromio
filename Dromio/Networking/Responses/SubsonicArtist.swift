import Foundation

struct SubsonicArtist: Codable, Equatable {
    let id: String
    let name: String
    let albumCount: Int?
    let album: [SubsonicAlbum]? // present only when getting a specific artist by id
    let roles: [String]?
    var sortName: String?
}
