import Foundation

/// State presented by AlbumsProcessor to AlbumsViewController.
@MainActor
struct AlbumsState: Equatable {
    var albums = [SubsonicAlbum]()
}

