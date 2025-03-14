import Foundation

/// Type of the array element of the `song` property of the SubsonicAlbum.
/// Serves as actual data for the app.
struct SubsonicSong: Codable, Equatable {
    let id: String
    let title: String
    let album: String?
    let artist: String?
    let displayComposer: String?
    let track: Int?
    let year: Int?
    let albumId: String?
    let suffix: String?
    let duration: Int?
    // Lots of other stuff I'm ignoring for now...
    // This, however, is internal to the app:
    var downloaded: Bool?
}
