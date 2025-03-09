import Foundation

struct SubsonicArtist: Codable, Equatable {
    let id: String
    let name: String
    let albumCount: Int?
    let roles: [String]?
    let sortName: String?
}
