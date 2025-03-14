import Foundation

/// Processor containing logic for the ArtistsViewController.
@MainActor
final class ArtistsProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<ArtistsEffect, ArtistsState>)?

    /// State to be presented to the presenter; mutating it presents.
    var state: ArtistsState = ArtistsState() {
        didSet {
            presenter?.present(state)
        }
    }

    func receive(_ action: ArtistsAction) async {
        switch action {
        case .allArtists:
            do {
                await presenter?.receive(.tearDownSearcher)
                let artists = try await caches.fetch(\.allArtists) {
                    try await services.requestMaker.getArtistsBySearch()
                }
                let artistsWhoAreArtists = artists.filter { ($0.roles ?? []).contains("artist") }
                state.listType = .allArtists
                state.artists = artistsWhoAreArtists
            } catch {
                print(error)
            }
        case .composers:
            do {
                await presenter?.receive(.tearDownSearcher)
                let artists = try await caches.fetch(\.allArtists) {
                    try await services.requestMaker.getArtistsBySearch()
                }
                let artistsWhoAreComposers = artists.filter { ($0.roles ?? []).contains("composer") }
                state.listType = .composers
                state.artists = artistsWhoAreComposers
            } catch {
                print(error)
            }
        case .showAlbums(let id):
            coordinator?.showAlbumsForArtist(state: AlbumsState(listType: .albumsForArtist(id: id)))
        case .albums:
            await presenter?.receive(.tearDownSearcher)
            coordinator?.dismissArtists()
        case .showPlaylist:
            coordinator?.showPlaylist()
        case .viewDidAppear:
            await presenter?.receive(.setUpSearcher)
        }
    }
}
