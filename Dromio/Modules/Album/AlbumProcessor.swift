import Foundation

/// Processor containing logic for the AlbumViewController.
final class AlbumProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<AlbumEffect, AlbumState>)?

    /// State to be presented to the presenter.
    var state: AlbumState = AlbumState()

    func receive(_ action: AlbumAction) async {
        switch action {
        case .initialData:
            guard !state.hasInitialData else {
                return
            }
            state.hasInitialData = true
            state.animateSpinner = true
            await presenter?.present(state)
            do {
                guard let albumId = state.albumId else { return }
                let songs = try await services.requestMaker.getSongsFor(albumId: albumId)
                state.songs = songs
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
        case .tapped(let song):
            var success = false
            do {
                try services.currentPlaylist.append(song)
                services.haptic.success()
                success = true
            } catch {
            }
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.2))
            }
            await presenter?.receive(.deselectAll)
            if success {
                await presenter?.receive(.animate(song: song))
                await presenter?.receive(.animatePlaylist)
            }
        case .showPlaylist:
            coordinator?.showPlaylist(state: nil)
        }
    }
}
