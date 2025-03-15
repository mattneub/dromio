import Foundation

/// Type of the array element of the `album` property of the AlbumsResponse.
/// Serves as actual data for the app.
struct SubsonicAlbum: Codable, Equatable, Sendable {
    let id: String
    let name: String
    var sortName: String?
    let artist: String?
    let songCount: Int
    let song: [SubsonicSong]? // absent for `getAlbumsList2`, but present for `getAlbum`
    // Lots of other stuff I'm ignoring for now.
}
