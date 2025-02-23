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
        case .initialData:
            do {
                let albums = try await services.requestMaker.getAlbumList()
                state.albums = albums
            } catch {
                print(error)
            }
        case .showAlbum(let id):
            coordinator?.showAlbum(albumId: id)
        case .showPlaylist:
            coordinator?.showPlaylist()
        }
    }
}
