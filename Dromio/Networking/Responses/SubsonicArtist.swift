import Foundation

/// Type of the array element of the ArtistIndex.
/// Serves as data for the actual app.
struct SubsonicArtist: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let albumCount: Int?
    let album: [SubsonicAlbum]? // present only when getting a specific artist by id
    let roles: [String]?
    var sortName: String?
}
