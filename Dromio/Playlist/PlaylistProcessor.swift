import Foundation
import Combine

/// Processor containing logic for the PlaylistViewController.
@MainActor
final class PlaylistProcessor: AsyncProcessor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any AsyncReceiverPresenter<PlaylistEffect, PlaylistState>)?

    /// State to be presented to the presenter.
    var state = PlaylistState()

    /// Pipeline subscribing to Download's `progress` during a download, so we can report progress.
    var downloadPipeline: AnyCancellable?

    /// Pipeline subscribing to Player's `currentSongId`, so we can display what's playing.
    var playerCurrentSongIdPipeline: AnyCancellable?

    /// Pipeline subscribing to Player's `playerState`, so we can display response to change of state.
    var playerStatePipeline: AnyCancellable?

    func receive(_ action: PlaylistAction) async {
        switch action {
        case .clear:
            services.haptic.impact()
            if state.jukeboxMode {
                try? await stopAndClearJukebox()
            } else {
                services.currentPlaylist.clear()
                services.player.clear()
                await services.download.clear()
                state.songs = services.currentPlaylist.list
                await presenter?.present(state)
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.3))
                }
                coordinator?.popPlaylist()
            }
        case .delete(let row):
            guard row < state.songs.count else { return }
            let song = state.songs[row]
            services.player.clear()
            do {
                try await services.download.delete(song: song)
                services.currentPlaylist.delete(song: song)
                try await configureSongs()
                state.animate = true
                await presenter?.present(state)
                state.animate = false
                if state.songs.isEmpty && !state.jukeboxMode {
                    try? await unlessTesting {
                        try? await Task.sleep(for: .seconds(0.3))
                    }
                    coordinator?.popPlaylist()
                }
            } catch {}
        case .editButton:
            services.player.clear()
            state.updateTableView = false
            state.editMode.toggle()
            await presenter?.present(state)
            state.updateTableView = true
            if !state.editMode {
                // present, thus cleaning up the datasource's data which may have become stale while editing
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.5))
                }
                await presenter?.present(state)
            }
        case .initialData:
            try? await configureSongs()
            await presenter?.present(state)
            setUpPipelines()
            services.currentPlaylist.setList(state.songs) // they must always be in sync, and we may have just filtered the list
        case .jukeboxButton:
            services.haptic.impact()
            state.jukeboxMode.toggle()
            await presenter?.present(state)
        case .move(let fromRow, let toRow):
            services.currentPlaylist.move(from: fromRow, to: toRow)
            var songs = state.songs
            guard fromRow < songs.count else { return }
            guard toRow < songs.count else { return }
            let song = songs.remove(at: fromRow)
            songs.insert(song, at: toRow)
            state.songs = songs
            await presenter?.present(state)
        case .playPause:
            services.haptic.impact()
            services.player.playPause()
        case .tapped(let song):
            let sequence = state.songs.buildSequence(startingWith: song)
            guard sequence.count > 0 else {
                return
            }
            services.haptic.success()
            Task { // don't let this delay also delay the start of playing
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.3))
                }
                await presenter?.receive(.deselectAll)
            }
            if state.jukeboxMode {
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
        let operation = services.backgroundTaskOperationMaker.make { @MainActor [weak self] in
            _ = try await services.download.download(song: song) // if already downloaded, no harm done
            await self?.markDownloaded(song: song)
            return ()
        }
        try await operation.start()
        // remainder, download and queue
        while !sequence.isEmpty {
            let song = sequence.removeFirst()
            let operation = services.backgroundTaskOperationMaker.make { @MainActor [weak self] in
                let url = try await services.download.download(song: song)
                services.player.playNext(url: url, song: song)
                await self?.markDownloaded(song: song)
                return ()
            }
            try await operation.start()
        }
    }

    /// Set `state.songs` based on the current playlist and what has been downloaded. This method
    /// promises not to generate any presentation of the state to the presenter; if the caller wants
    /// to present after calling this method, that is up to the caller.
    private func configureSongs() async throws {
        let sequence = SimpleAsyncSequence(array: services.currentPlaylist.list)
        var songs = [SubsonicSong]()
        if state.offlineMode {
            // in offline mode, _filter out_ those that songs are not downloaded, and mark
            // as downloaded _all_ that remain
            let result = sequence.filter {
                await services.download.isDownloaded(song: $0)
            }.map {
                var song = $0
                song.downloaded = true
                return song
            }
            songs = try await result.array()
        } else {
            // in normal mode, use _all_ the songs. and mark as downloaded only those that _are_ downloaded
            let result = SimpleAsyncSequence(array: services.currentPlaylist.list).map {
                var song = $0
                song.downloaded = await services.download.isDownloaded(song: song)
                return song
            }
            songs = try await result.array()
        }
        state.songs = songs
        // no presentation took place during this method! it is up to the caller to present
    }

    /// Given a song, mark it as downloaded in `state.songs`. This is O(1) but so what?
    /// - Parameter song: The song.
    private func markDownloaded(song: SubsonicSong) async {
        if let index = state.songs.firstIndex(where: { $0.id == song.id }) {
            if !state.songs[index].downloaded { // do not present unnecessarily
                state.songs[index].downloaded = true
                await presenter?.present(state)
            }
        }
    }
    
    /// Given a sequence of songs, tell the jukebox to play them in order.
    /// - Parameter sequence: The sequence of songs.
    private func playOnJukebox(sequence: [SubsonicSong]) async throws {
        try await stopAndClearJukebox()
        // TODO: we are not actually using the status returned for anything
        for song in sequence {
            let status = try await services.requestMaker.jukebox(action: .add, songId: song.id)
            dump(status)
        }
        let status = try await services.requestMaker.jukebox(action: .start)
        dump(status)
    }

    /// Tell the jukebox to stop playing and to empty its queue.
    private func stopAndClearJukebox() async throws {
        // TODO: we are not actually using the status returned for anything
        var status = try await services.requestMaker.jukebox(action: .stop)
        dump(status)
        status = try await services.requestMaker.jukebox(action: .clear)
        dump(status)
    }

    /// Configure our pipelines, just once. Called from `receive(.initialData)`. If it were to be called
    /// a second time, nothing would happen.
    private func setUpPipelines() {
        if downloadPipeline == nil {
            downloadPipeline = services.networker.progress.sink { [weak presenter] pair in
                Task {
                    await presenter?.receive(.progress(pair.id, pair.fraction))
                }
            }
        }
        if playerCurrentSongIdPipeline == nil {
            playerCurrentSongIdPipeline = services.player.currentSongIdPublisher.removeDuplicates().sink { [weak self] songId in
                guard let self else { return }
                state.currentSongId = songId
                Task {
                    await presenter?.present(state)
                    if let songId {
                        try? await services.requestMaker.scrobble(songId: songId)
                    }
                }
            }
        }
        if playerStatePipeline == nil {
            playerStatePipeline = services.player.playerStatePublisher.removeDuplicates().sink { [weak presenter] playerState in
                Task {
                    await presenter?.receive(.playerState(playerState))
                }
            }
        }
    }
}
