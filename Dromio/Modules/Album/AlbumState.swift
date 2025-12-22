import Foundation

/// State presented by AlbumProcessor to AlbumViewController.
struct AlbumState: Equatable {
    var albumId: String?
    var albumTitle: String?
    var songs = [SubsonicSong]()
    var hasInitialData = false // scratchpad
    var animateSpinner = false
}

