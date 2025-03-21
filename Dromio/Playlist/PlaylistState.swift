import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
@MainActor
struct PlaylistState: Equatable {
    var currentSongId: String? // id of the currently playing song, from the current playlist
    var jukebox = false // _always_ false, at the moment
    var songs = [SubsonicSong]()
}

