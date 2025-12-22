import Foundation

/// State presented by ArtistsProcessor to ArtistsViewController.
struct ArtistsState: Equatable {
    var listType: ListType = .allArtists
    var artists = [SubsonicArtist]()
    var animateSpinner = false
    var hasInitialData = false // scratchpad

    enum ListType {
        case allArtists
        case composers
    }
}

