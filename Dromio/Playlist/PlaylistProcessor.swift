import Foundation
import Combine

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

    /// Pipeline subscribing to Download's `progress` during a download, so we can report progress.
    var pipeline: AnyCancellable?

    func receive(_ action: PlaylistAction) async {
        switch action {
        case .clear:
            services.currentPlaylist.clear()
            services.player.clear()
            await services.download.clear()
            state.songs = services.currentPlaylist.list
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.3))
            }
            coordinator?.popPlaylist()
        case .initialData:
            var songs = services.currentPlaylist.list
            for index in songs.indices {
                let url = try? await services.download.downloadedURL(for: songs[index])
                songs[index].downloaded = (url != nil)
            }
            state.songs = songs
            // set up pipeline, only once
            if pipeline == nil, let presenter = presenter as? any Receiver<PlaylistEffect> {
                pipeline = services.networker.progress.sink { [weak presenter] pair in
                    Task {
                        await presenter?.receive(.progress(pair.id, pair.fraction))
                    }
                }
            }
        case .tapped(let song):
            let sequence = services.currentPlaylist.buildSequence(startingWith: song)
            guard sequence.count > 0 else {
                return
            }
            services.haptic.success()
            try? services.audioSession.setActive(true, options: [])
            Task { // don't let this delay also delay the start of playing
                try? await Task.sleep(for: .seconds(unlessTesting(0.3)))
                await (presenter as? any Receiver<PlaylistEffect>)?.receive(.deselectAll)
            }
            try? await play(sequence: sequence)
        }
    }

    /// Given a sequence (array) of songs, line them all up to be played in order, by downloading
    /// each one in sequence and appending it to the player's queue, except for the first one which
    /// should start playing by streaming and then also download. As each download succeeds, mark
    /// that song as `downloaded`.
    /// - Parameter sequence: The sequence (array) of songs.
    ///
    func play(sequence: [SubsonicSong]) async throws {
        var sequence = sequence
        // first one, stream / play, and also download
        let song = sequence.removeFirst()
        let url = try await services.requestMaker.stream(songId: song.id)
        services.player.play(url: url, song: song)
        let operation = BackgroundTaskOperation<Void> { @MainActor [weak self] in
            _ = try await services.download.download(song: song)
            self?.markDownloaded(song: song)
        }
        try await operation.start()
        // remainder, download and queue
        while !sequence.isEmpty {
            let song = sequence.removeFirst()
            let operation = BackgroundTaskOperation<Void> { @MainActor [weak self] in
                let url = try await services.download.download(song: song)
                services.player.playNext(url: url, song: song)
                self?.markDownloaded(song: song)
            }
            try await operation.start()
        }
    }

    private func markDownloaded(song: SubsonicSong) {
        if let index = state.songs.firstIndex(where: { $0.id == song.id }) {
            state.songs[index].downloaded = true
        }
    }
}
