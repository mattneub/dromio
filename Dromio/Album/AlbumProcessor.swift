import Foundation

/// Processor containing logic for the AlbumsViewController.
@MainActor
final class AlbumProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any Presenter<AlbumState>)?

    /// State to be presented to the presenter; mutating it presents.
    var state: AlbumState = AlbumState() {
        didSet {
            presenter?.present(state)
        }
    }

    func receive(_ action: AlbumAction) async {
        switch action {
        case .initialData:
            do {
                guard let albumId = state.albumId else { return }
                let songs = try await services.requestMaker.getSongsFor(albumId: albumId)
                state.songs = songs
            } catch {
                print(error)
            }
        }
    }
}
