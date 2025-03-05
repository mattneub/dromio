import Foundation

/// State presented by AlbumProcessor to AlbumViewController.
@MainActor
struct AlbumState: Equatable {
    var albumId: String?
    var albumTitle: String?
    var totalCount = 0 // TODO: do we need this? can't we just use songs.count?
    var songs = [SubsonicSong]()
}

