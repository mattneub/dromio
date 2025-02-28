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
            let sequence = services.currentPlaylist.buildSequence(startingWith: song)
            guard sequence.count > 0 else {
                return
            }
            services.haptic.success()
            try? services.audioSession.setActive(true, options: [])
            try? await play(sequence: sequence)
        }
    }

    /// Given a sequence (array) of songs, line them all up to be played in order, by downloading
    /// each one in sequence and appending it to the player's queue, except for the first one which
    /// should start playing as soon as it is finished downloading.
    /// - Parameter sequence: The sequence (array) of songs.
    ///
    func play(sequence: [SubsonicSong]) async throws {
        var sequence = sequence
        // first one, download and play
        let song = sequence.removeFirst()
        let operation = BackgroundTaskOperation<Void> { @MainActor in
            let url = try await services.download.download(song: song)
            services.player.play(url: url, song: song)
        }
        try await operation.start()
        // remainder, download and queue
        while !sequence.isEmpty {
            let song = sequence.removeFirst()
            let operation = BackgroundTaskOperation<Void> { @MainActor in
                let url = try await services.download.download(song: song)
                services.player.playNext(url: url, song: song)
            }
            try await operation.start()
        }
    }
}
