import Foundation

/// State presented by AlbumProcessor to AlbumViewController.
@MainActor
struct AlbumState: Equatable {
    var albumId: String?
    var songs = [SubsonicSong]()
}

