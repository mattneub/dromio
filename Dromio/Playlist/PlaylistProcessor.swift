import Foundation

/// Processor containing logic for the PlaylistViewController.
@MainActor
final class PlaylistProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any Presenter<PlaylistState>)?

    /// State to be presented to the presenter; mutating it presents.
    var state: PlaylistState = PlaylistState() {
        didSet {
            presenter?.present(state)
        }
    }

    func receive(_ action: PlaylistAction) async {
        switch action {
        case .initialData:
            state.songs = services.currentPlaylist.list
        case .tapped(let song):
            do {
                services.haptic.success()
                try? services.audioSession.setActive(true, options: [])
                let url = try await services.download.download(song: song)
                services.player.play(url: url, song: song)
            } catch {
                print(error)
            }
        }
    }
}
