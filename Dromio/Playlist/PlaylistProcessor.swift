import Foundation
import Combine

/// Processor containing logic for the PlaylistViewController.
@MainActor
final class PlaylistProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<PlaylistEffect, PlaylistState>)?

    /// State to be presented to the presenter; mutating it presents, unless `noPresentation` forbids.
    var noPresentation = false
    var state = PlaylistState() {
        didSet {
            if noPresentation {
                noPresentation = false
            } else {
                presenter?.present(state)
            }
        }
    }

    /// Pipeline subscribing to Download's `progress` during a download, so we can report progress.
    var downloadPipeline: AnyCancellable?

    /// Pipeline subscribing to Player's `currentSongId`, so we can display what's playing.
    var playerPipeline: AnyCancellable?

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
            // collection songs, mark downloaded-ness
            noPresentation = true
            state.songs = services.currentPlaylist.list
            for song in state.songs {
                if let _ = try? await services.download.downloadedURL(for: song) {
                    noPresentation = true
                    markDownloaded(song: song)
                }
            }
            presenter?.present(state)
            // set up pipelines, only once
            if downloadPipeline == nil, let presenter {
                downloadPipeline = services.networker.progress.sink { [weak presenter] pair in
                    Task {
                        await presenter?.receive(.progress(pair.id, pair.fraction))
                    }
                }
            }
            if playerPipeline == nil {
                playerPipeline = services.player.currentSongIdPublisher.sink { [weak self] songId in
                    logger.log("playlist processor setting current item to \(songId ?? "nil", privacy: .public)")
                    self?.state.currentSongId = songId
                }
            }
        case .jukeboxButton:
            state.jukebox.toggle()
        case .tapped(let song):
            let sequence = state.songs.buildSequence(startingWith: song)
            guard sequence.count > 0 else {
                return
            }
            services.haptic.success()
            Task { // don't let this delay also delay the start of playing
                try? await Task.sleep(for: .seconds(unlessTesting(0.3)))
                await presenter?.receive(.deselectAll)
            }
            if state.jukebox { // always false, this feature is withdrawn
                try? await playOnJukebox(sequence: sequence)
            } else {
                try? await play(sequence: sequence)
            }
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
        // first one, stream / play, and also download — but if _already_ downloaded, just play
        let song = sequence.removeFirst()
        if let url = try? await services.download.downloadedURL(for: song) {
            services.player.play(url: url, song: song)
        } else if let url = try? await services.requestMaker.stream(songId: song.id) {
            services.player.play(url: url, song: song)
        }
        let operation = BackgroundTaskOperation<Void> { @MainActor [weak self] in
            _ = try await services.download.download(song: song) // if already downloaded, no harm done
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

    /// This code is provisional and never runs, because I can't get jukebox working on my server.
    private func playOnJukebox(sequence: [SubsonicSong]) async throws {
        var status = try await services.requestMaker.jukebox(additional: ["action": "stop"])
        dump(status)
        status = try await services.requestMaker.jukebox(additional: ["action": "clear"])
        dump(status)
        for song in sequence {
            status = try await services.requestMaker.jukebox(additional: ["action": "add", "id": song.id])
            dump(status)
        }
        status = try await services.requestMaker.jukebox(additional: ["action": "start"])
        dump(status)
    }
}
