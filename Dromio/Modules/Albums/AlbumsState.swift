import Foundation

/// State presented by AlbumsProcessor to AlbumsViewController.
struct AlbumsState: Equatable {
    var showTitle = false // do not show title until data is ready
    var listType: ListType = .allAlbums
    var albums = [SubsonicAlbum]()
    var animateSpinner = false
    var currentFolder: String? = nil
    var hasInitialData = false // scratchpad

    /// The albums view controller comes in three "flavors" or "modes". This enum specifies
    /// which one we're in.
    enum ListType: Equatable {
        case allAlbums
        case randomAlbums
        // the `id` is the id of the artist whose albums we're showing
        case albumsForArtist(id: String, source: Source)

        enum Source: Equatable {
            case artists
            case composers(name: String)
        }
    }
}

