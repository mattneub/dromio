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
        case .initialData:
            // how we fetch the initial data depends on what "mode" of albums this is
            switch state.listType {
            case .allAlbums:
                await receive(.allAlbums)
            case .albumsForArtist(let id):
                do {
                    let albums = try await services.requestMaker.getAlbumsFor(artistId: id)
                    state.albums = albums
                } catch {
                    print(error)
                }
            default: break
            }
        case .allAlbums:
            do {
                await presenter?.receive(.tearDownSearcher)
                let albums = try await caches.fetch(\.albumsList) {
                    try await services.requestMaker.getAlbumList()
                }
                state.listType = .allAlbums
                state.albums = albums
            } catch {
                print(error)
            }
        case .randomAlbums:
            do {
                await presenter?.receive(.tearDownSearcher)
                let albums = try await services.requestMaker.getAlbumsRandom()
                state.listType = .randomAlbums
                state.albums = albums
            } catch {
                print(error)
            }
        case .showAlbum(let id):
            guard let album = state.albums.first(where: { $0.id == id }) else {
                return
            }
            coordinator?.showAlbum(albumId: id, title: album.name)
        case .artists:
            await presenter?.receive(.tearDownSearcher)
            coordinator?.showArtists()
        case .showPlaylist:
            coordinator?.showPlaylist()
        case .viewDidAppear:
            await presenter?.receive(.setUpSearcher)
        }
    }
}
