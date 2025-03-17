import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
@MainActor
struct PlaylistState: Equatable {
    var jukebox = false
    var songs = [SubsonicSong]()
}

