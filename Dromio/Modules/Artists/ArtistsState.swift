import Foundation

/// State presented by ArtistsProcessor to ArtistsViewController.
struct ArtistsState: Equatable {
    var showTitle = false // do not show title until data is ready
    var listType: ListType = .allArtists
    var currentFolder: String?
    var artists = [SubsonicArtist]()
    var animateSpinner = false
    var hasInitialData = false // scratchpad

    enum ListType {
        case allArtists
        case composers
    }
}

