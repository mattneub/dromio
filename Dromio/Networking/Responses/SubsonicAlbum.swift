import Foundation

/// Type of the array element of the `album` property of the AlbumsResponse.
/// Serves as data for the actual app.
struct SubsonicAlbum: Codable, Equatable, Sendable {
    let id: String
    let name: String
    var sortName: String?
    let artist: String?
    let songCount: Int
    let song: [SubsonicSong]? // absent for `getAlbumList2`, but present for `getAlbum`
    // Lots of other stuff I'm ignoring for now.
}
