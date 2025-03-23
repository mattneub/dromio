import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
@MainActor
struct PlaylistState: Equatable {
    var currentSongId: String? // id of the currently playing song, from the current playlist
    var jukeboxMode = false
    var offlineMode = false
    var songs = [SubsonicSong]()

    // Logic for when to show the clear button
    var showClearButtonAndJukeboxButton: Bool {
        offlineMode == false
    }

    // Logic for when to show the playpause button
    var showPlayPauseButton: Bool {
        currentSongId != nil && !jukeboxMode
    }
}

