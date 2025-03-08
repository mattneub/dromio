import Foundation

/// State presented by AlbumsProcessor to AlbumsViewController.
@MainActor
struct AlbumsState: Equatable {
    var listType: ListType = .allAlbums
    var albums = [SubsonicAlbum]()

    enum ListType {
        case allAlbums
        case randomAlbums
    }
}

