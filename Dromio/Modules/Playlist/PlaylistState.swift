import Foundation

/// State presented by PlaylistProcessor to PlaylistViewController.
struct PlaylistState: Equatable {
    var currentSongId: String? // id of the currently playing song, from the current playlist
    var editMode = false
    var jukeboxMode = false
    var offlineMode = false
    var resumableSong: ResumableSongInfo?
    var songs = [SubsonicSong]()
    var animate = false // whether to animate the current presentation (in the table view)
    var updateTableView = true // whether to update the table view with the given state info

    // Logic for when to show the clear button
    var showClearButtonAndJukeboxButton: Bool {
        offlineMode == false && editMode == false
    }

    // Logic for when to show the playpause button
    var showPlayPauseButton: Bool {
        currentSongId != nil && jukeboxMode == false && editMode == false
    }

    // Logic for when to show the resume button
    var showResumeButton: Bool {
        resumableSong != nil
    }
}

/// Value struct describing our resumable paused position: what song it is and where in that song.
struct ResumableSongInfo: Equatable {
    let id: String
    let seconds: Double
}

