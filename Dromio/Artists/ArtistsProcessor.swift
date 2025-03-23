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
        case .albums:
            await presenter?.receive(.tearDownSearcher)
            coordinator?.dismissArtists()
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
                logger.log("\(error.localizedDescription, privacy: .public)")
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
                logger.log("\(error.localizedDescription, privacy: .public)")
            }
        case .server:
            coordinator?.dismissToPing()
        case .showAlbums(let id):
            switch state.listType {
            case .allArtists:
                coordinator?.showAlbumsForArtist(
                    state: AlbumsState(
                        listType: .albumsForArtist(id: id, source: .artists)
                    )
                )
            case .composers:
                guard let name = state.artists.first(where: { $0.id == id })?.name else { return }
                coordinator?.showAlbumsForArtist(
                    state: AlbumsState(
                        listType: .albumsForArtist(id: id, source: .composers(name: name))
                    )
                )
            }
        case .showPlaylist:
            coordinator?.showPlaylist(state: nil)
        case .viewDidAppear:
            await presenter?.receive(.setUpSearcher)
        }
    }
}
