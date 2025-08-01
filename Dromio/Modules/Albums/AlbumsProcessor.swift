import Foundation

/// Processor containing logic for the AlbumsViewController.
@MainActor
final class AlbumsProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<AlbumsEffect, AlbumsState>)?

    /// Cycler, so that we can dispatch actions to ourself and test that we did so.
    lazy var cycler: Cycler = Cycler(processor: self)

    /// State to be presented to the presenter.
    var state: AlbumsState = AlbumsState()

    func receive(_ action: AlbumsAction) async {
        switch action {
        case .allAlbums:
            do {
                state.animateSpinner = true
                await presenter?.present(state)
                await presenter?.receive(.tearDownSearcher)
                let albums = try await services.cache.fetch(\.allAlbums) {
                    let albums = try await services.requestMaker.getAlbumList()
                    return albums.sorted
                }
                state.listType = .allAlbums
                state.albums = albums
                await presenter?.present(state)
                await presenter?.receive(.setUpSearcher)
                await presenter?.receive(.scrollToZero)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.2))
                }
                state.animateSpinner = false
                await presenter?.present(state)
            } catch {
                logger.debug("\(error.localizedDescription, privacy: .public)")
                state.animateSpinner = false
                await presenter?.present(state)
            }
        case .artists:
            coordinator?.showArtists()
        case .initialData:
            guard !state.hasInitialData else { // do this only the very first time
                return
            }
            state.hasInitialData = true
            state.animateSpinner = true
            await presenter?.present(state)
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.4))
            }
            // how we fetch the initial data depends on what "mode" of albums this is
            switch state.listType {
            case .allAlbums:
                await cycler.receive(.allAlbums)
            case .albumsForArtist(let id, let source):
                do {
                    switch source {
                    case .artists:
                        let albums = try await services.requestMaker.getAlbumsFor(artistId: id)
                        state.albums = albums.sorted
                    case .composers(let name):
                        let songs = try await services.requestMaker.getSongsBySearch(query: name)
                        state.albums = albumsForComposer(songs: songs, id: id) // already sorted
                    }
                    await presenter?.present(state)
                    try? await unlessTesting {
                        try? await Task.sleep(for: .seconds(0.2))
                    }
                    state.animateSpinner = false
                    await presenter?.present(state)
                } catch {
                    logger.debug("\(error.localizedDescription, privacy: .public)")
                    state.animateSpinner = false
                    await presenter?.present(state)
                }
            default: break
            }
        case .randomAlbums:
            do {
                state.animateSpinner = true
                await presenter?.present(state)
                await presenter?.receive(.tearDownSearcher)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.4))
                }
                let albums = try await services.requestMaker.getAlbumsRandom()
                state.listType = .randomAlbums
                state.albums = albums
                await presenter?.present(state)
                await presenter?.receive(.scrollToZero)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.2))
                }
                state.animateSpinner = false
                await presenter?.present(state)
            } catch {
                logger.debug("\(error.localizedDescription, privacy: .public)")
                state.animateSpinner = false
                await presenter?.present(state)
            }
        case .server:
            coordinator?.dismissToPing()
        case .showAlbum(let id):
            guard let album = state.albums.first(where: { $0.id == id }) else {
                return
            }
            coordinator?.showAlbum(albumId: id, title: album.name)
        case .showPlaylist:
            coordinator?.showPlaylist(state: nil)
        }
    }
    
    /// Utility called by .albumsForArtist when the artist is a composer. This is the only query where
    /// we cannot ask Navidrome directly for the answer: in what albums is this artist a composer?
    /// Therefore we have to get the _songs_ for this composer and reduce that to a list of the
    /// albums containing those songs. Luckily, we _already_ a list of _all_ albums, so even though we
    /// have to go from composer to songs to albums, this move is fast.
    /// - Parameters:
    ///   - songs: Songs (returned by a `search3` query on the composer's name).
    ///   - id: The composer's id.
    /// - Returns: The list of albums containing a song by that composer.
    ///
    private func albumsForComposer(songs: [SubsonicSong], id: String) -> [SubsonicAlbum] {
        // filter to songs containing a contributor whose role is composer and whose id is this id
        let songsByThisComposer = songs.filter { song in
            for contributor in (song.contributors ?? []) {
                if contributor.role == "composer" && contributor.artist.id == id {
                    return true
                }
            }
            return false
        }
        // a song has an albumId so we can unique to those as a set
        let albumsIds = Set(songsByThisComposer.map { $0.albumId })
        // now, using the existing list of albums, we can filter to the albums with those ids
        let allAlbums = services.cache.allAlbums ?? [] // we know we have it, and it is sorted
        return allAlbums.filter({ albumsIds.contains($0.id) })
    }
}
