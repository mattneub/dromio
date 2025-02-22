import Foundation

/// Type of the array element of the `song` property of the SubsonicAlbum.
/// Serves as actual data for the app.
struct SubsonicSong: Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let track: Int
    let albumId: String?
    // Lots of other stuff I'm ignoring for now
}
