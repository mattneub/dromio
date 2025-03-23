import Foundation

/// Processor containing logic for the AlbumsViewController.
@MainActor
final class AlbumsProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<AlbumsEffect, AlbumsState>)?

    /// State to be presented to the presenter; mutating it presents.
    var state: AlbumsState = AlbumsState() {
        didSet {
            presenter?.present(state)
        }
    }

    func receive(_ action: AlbumsAction) async {
        switch action {
        case .allAlbums:
            do {
                await presenter?.receive(.tearDownSearcher)
                let albums = try await caches.fetch(\.albumsList) {
                    try await services.requestMaker.getAlbumList()
                }
                state.listType = .allAlbums
                state.albums = albums
            } catch {
                logger.log("\(error.localizedDescription, privacy: .public)")
            }
        case .artists:
            await presenter?.receive(.tearDownSearcher)
            coordinator?.showArtists()
        case .initialData:
            // how we fetch the initial data depends on what "mode" of albums this is
            switch state.listType {
            case .allAlbums:
                await receive(.allAlbums)
            case .albumsForArtist(let id, let source):
                do {
                    switch source {
                    case .artists:
                        let albums = try await services.requestMaker.getAlbumsFor(artistId: id)
                        state.albums = albums
                    case .composers(let name):
                        let songs = try await services.requestMaker.getSongsBySearch(query: name)
                        state.albums = albumsForComposer(songs: songs, id: id)
                    }
                } catch {
                    logger.log("\(error.localizedDescription, privacy: .public)")
                }
            default: break
            }
        case .randomAlbums:
            do {
                await presenter?.receive(.tearDownSearcher)
                let albums = try await services.requestMaker.getAlbumsRandom()
                state.listType = .randomAlbums
                state.albums = albums
            } catch {
                logger.log("\(error.localizedDescription, privacy: .public)")
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
        case .viewDidAppear:
            await presenter?.receive(.setUpSearcher)
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
    func albumsForComposer(songs: [SubsonicSong], id: String) -> [SubsonicAlbum] {
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
        let allAlbums = caches.albumsList ?? [] // we know we have it
        return allAlbums.filter({ albumsIds.contains($0.id)}).sorted
    }
}
