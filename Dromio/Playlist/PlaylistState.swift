import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
@MainActor
struct PlaylistState: Equatable {
    var currentItem: String?
    var jukebox = false // _always_ false, at the moment
    var songs = [SubsonicSong]()
}

