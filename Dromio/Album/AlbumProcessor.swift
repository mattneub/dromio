import Foundation

/// Processor containing logic for the AlbumViewController.
@MainActor
final class AlbumProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<AlbumEffect, AlbumState>)?

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
                logger.log("\(error.localizedDescription, privacy: .public)")
            }
        case .tapped(let song):
            do {
                try services.currentPlaylist.append(song)
                services.haptic.success()
                await presenter?.receive(.animatePlaylist)
            } catch {
                services.haptic.failure()
            }
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.3))
            }
            await presenter?.receive(.deselectAll)
        case .showPlaylist:
            coordinator?.showPlaylist(state: nil)
        }
    }
}
