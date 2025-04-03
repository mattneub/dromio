import Foundation

/// Processor containing logic for the ArtistsViewController.
@MainActor
final class ArtistsProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<ArtistsEffect, ArtistsState>)?

    /// State to be presented to the presenter.
    var state: ArtistsState = ArtistsState()

    func receive(_ action: ArtistsAction) async {
        switch action {
        case .albums:
            coordinator?.dismissArtists()
        case .allArtists:
            do {
                state.animateSpinner = true
                await presenter?.present(state)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.4))
                }
                let artists = try await caches.fetch(\.allArtists) {
                    try await services.requestMaker.getArtistsBySearch()
                }
                let artistsWhoAreArtists = artists.filter { ($0.roles ?? []).contains("artist") }
                state.listType = .allArtists
                state.artists = artistsWhoAreArtists
                await presenter?.present(state)
                await presenter?.receive(.setUpSearcher)
                await presenter?.receive(.scrollToZero)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.2))
                }
                state.animateSpinner = false
                await presenter?.present(state)
            } catch {
                logger.log("\(error.localizedDescription, privacy: .public)")
                state.animateSpinner = false
                await presenter?.present(state)
            }
        case .composers:
            do {
                state.animateSpinner = true
                await presenter?.present(state)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.4))
                }
                let artists = try await caches.fetch(\.allArtists) {
                    try await services.requestMaker.getArtistsBySearch()
                }
                let artistsWhoAreComposers = artists.filter { ($0.roles ?? []).contains("composer") }
                state.listType = .composers
                state.artists = artistsWhoAreComposers
                await presenter?.present(state)
                await presenter?.receive(.setUpSearcher)
                await presenter?.receive(.scrollToZero)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.2))
                }
                state.animateSpinner = false
                await presenter?.present(state)
            } catch {
                logger.log("\(error.localizedDescription, privacy: .public)")
                state.animateSpinner = false
                await presenter?.present(state)
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
        case .viewIsAppearing:
            guard !state.hasInitialData else {
                return
            }
            state.hasInitialData = true
            await receive(.allArtists)
        }
    }
}
