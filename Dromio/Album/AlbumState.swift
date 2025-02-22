import Foundation

/// State presented by AlbumsProcessor to AlbumsViewController.
@MainActor
struct AlbumState: Equatable {
    var albumId: String?
    var songs = [SubsonicSong]()
}

