import Foundation

/// Processor containing logic for the AlbumsViewController.
@MainActor
final class AlbumsProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any Presenter<AlbumsState>)?

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
                let albums = try await services.requestMaker.getAlbumList()
                state.listType = .allAlbums
                state.albums = albums
            } catch {
                print(error)
            }
        case .randomAlbums:
            do {
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
        case .showPlaylist:
            coordinator?.showPlaylist()
        }
    }
}
