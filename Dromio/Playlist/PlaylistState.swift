import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
@MainActor
struct PlaylistState: Equatable {
    var currentSongId: String? // id of the currently playing song, from the current playlist
    var jukeboxMode = false
    var songs = [SubsonicSong]()

    // Logic for when to show the playpause button
    var showPlayPauseButton: Bool {
        currentSongId != nil && !jukeboxMode
    }
}

