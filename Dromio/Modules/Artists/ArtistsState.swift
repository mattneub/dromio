import Foundation

/// State presented by ArtistsProcessor to ArtistsViewController.
@MainActor
struct ArtistsState: Equatable {
    var listType: ListType = .allArtists
    var artists = [SubsonicArtist]()
    var animateSpinner = false
    var hasInitialData = false

    enum ListType {
        case allArtists
        case composers
    }
}

