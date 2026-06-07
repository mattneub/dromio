import Foundation
import Observation

/// Processor containing logic for the PlaylistViewController.
final class PlaylistProcessor: Processor {
    /// Reference to the coordinator, set by coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the view controller, set by coordinator on creation.
    weak var presenter: (any ReceiverPresenter<PlaylistEffect, PlaylistState>)?

    /// State to be presented to the presenter.
    var state = PlaylistState()

    var task1: Task<(), Never>?
    var task2: Task<(), Never>?
    var task3: Task<(), Never>?

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
                await services.networker.clear()
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
            await services.networker.clear()
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
            await services.networker.clear()
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
            services.currentPlaylist.setList(state.songs) // they must always be in sync, and we may have just filtered the list
            await checkForResumability()
            await presenter?.present(state)
            setUpPipelines()
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
        case .resume:
            guard let currentSongId = state.resumableSong?.id,
                  let currentSongSeconds = state.resumableSong?.seconds else {
                state.resumableSong = nil
                await presenter?.present(state)
                services.persistence.saveCurrentPaused(currentSongId: nil, currentSongSeconds: nil)
                return
            }
            let sequence = state.songs.buildSequence(startingWith: currentSongId)
            guard sequence.count > 0, await checkAllSongsDownloaded(songs: sequence) else {
                state.resumableSong = nil
                await presenter?.present(state)
                services.persistence.saveCurrentPaused(currentSongId: nil, currentSongSeconds: nil)
                return
            }
            services.player.clear()
            await services.networker.clear()
            services.haptic.success()
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.3))
            }
            await presenter?.receive(.deselectAll)
            try? await play(sequence: sequence, seconds: currentSongSeconds)
            state.resumableSong = nil
            await presenter?.present(state)
            services.persistence.saveCurrentPaused(currentSongId: nil, currentSongSeconds: nil)
        case .tapped(let song):
            let sequence = state.songs.buildSequence(startingWith: song.id)
            guard sequence.count > 0 else {
                return
            }
            services.player.clear()
            await services.networker.clear()
            services.haptic.success()
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.3))
            }
            await presenter?.receive(.deselectAll)
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
    private func play(sequence: [SubsonicSong]) async throws {
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

    /// Given a sequence (array) of _already downloaded_ songs, line them all up to be played in order
    /// by appending each one to the player's queue, except for the first one which
    /// should start playing at the given position. Called by `.resume`.
    /// - Parameters:
    ///   - sequence: The sequence (array) of songs.
    ///   - seconds: The position within the first song at which to start playing.
    ///
    private func play(sequence: [SubsonicSong], seconds: Double) async throws {
        var sequence = sequence
        let song = sequence.removeFirst()
        guard let url = try await services.download.downloadedURL(for: song) else {
            return
        }
        services.player.play(url: url, song: song, seconds: seconds)
        for song in sequence {
            guard let url = try await services.download.downloadedURL(for: song) else {
                return
            }
            services.player.playNext(url: url, song: song)
        }
    }

    /// Check for resumability and set the state accordingly. We are resumable if (1) there are
    /// current paused id and paused seconds in persistence, (2) that song is in the state's `songs`,
    /// and (3) that song and all subsequent songs in the state's `songs` are already downloaded.
    /// If any of those tests fails, set the state's `resumableSong` to `nil` and bail out.
    /// Called by `.initialData`.
    private func checkForResumability() async {
        guard let currentId = services.persistence.loadCurrentPausedId() else {
            state.resumableSong = nil
            return
        }
        guard let currentSeconds = services.persistence.loadCurrentPausedSeconds() else {
            state.resumableSong = nil
            return
        }
        let songs = state.songs.buildSequence(startingWith: currentId)
        guard !songs.isEmpty else {
            state.resumableSong = nil
            return
        }
        guard await checkAllSongsDownloaded(songs: songs) else {
            state.resumableSong = nil
            return
        }
        state.resumableSong = .init(id: currentId, seconds: currentSeconds)
    }

    /// Utility method: given an array of songs, report whether they are all downloaded.
    /// Called by `checkForResumability` in `.initialData` and also directly by `.resume`.
    /// Does not throw; an error simply returns `false`.
    private func checkAllSongsDownloaded(songs: [SubsonicSong]) async -> Bool {
        do {
            let sequence = SimpleAsyncSequence(array: songs)
            let downloadedSongs = sequence.filter {
                await services.download.isDownloaded(song: $0)
            }
            let downloadedSongsArray = try await downloadedSongs.array()
            return downloadedSongsArray.count == songs.count
        } catch {
            return false
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
            _ = try await services.requestMaker.jukebox(action: .add, songId: song.id)
        }
        _ = try await services.requestMaker.jukebox(action: .start)
    }

    /// Tell the jukebox to stop playing and to empty its queue.
    private func stopAndClearJukebox() async throws {
        // TODO: we are not actually using the status returned for anything
        _ = try await services.requestMaker.jukebox(action: .stop)
        _ = try await services.requestMaker.jukebox(action: .clear)
    }

    /// Configure our pipelines. Called from `receive(.initialData)`.
    private func setUpPipelines() {
        // New strategy; the tasks can outlive the view controller, so if we're told to set them
        // up again, delete and recreate them.
        task1?.cancel(); task1 = nil
        task2?.cancel(); task2 = nil
        task3?.cancel(); task3 = nil
        do {
            let observations = Observations {
                return services.networker.progress
            }
            task1 = Task { [weak self] in
                for await pair in observations {
                    guard self?.presenter != nil else {
                        break
                    }
                    await self?.presenter?.receive(.progress(pair.id, pair.fraction))
                }
            }
        }
        do {
            let observations = Observations {
                return services.player.currentSongIdPublisher
            }
            task2 = Task { [weak self] in
                for await songId in observations {
                    guard self?.presenter != nil else {
                        break
                    }
                    if let self {
                        state.currentSongId = songId
                        if state.currentSongId != nil {
                            // in case user taps to start playing while Resume button is showing;
                            // since we are going to be presenting anyway, we may as well
                            // hitch a ride here
                            state.resumableSong = nil
                        }
                        await presenter?.present(state)
                    }
                    if let songId {
                        try? await services.requestMaker.scrobble(songId: songId)
                    }
                }
            }
        }
        do {
            let observations = Observations {
                return services.player.playerStatePublisher
            }
            task3 = Task { [weak self] in
                for await playerState in observations {
                    guard self?.presenter != nil else {
                        break
                    }
                    await self?.presenter?.receive(.playerState(playerState))
                    switch playerState {
                    case let .paused(seconds):
                        try? await unlessTesting {
                            try? await Task.sleep(for: .seconds(0.2)) // let current song id propagate
                        }
                        if let currentSongId = self?.state.currentSongId {
                            services.persistence.saveCurrentPaused(
                                currentSongId: currentSongId,
                                currentSongSeconds: seconds
                            )
                        } else {
                            fallthrough
                        }
                    case .empty, .playing:
                        services.persistence.saveCurrentPaused(
                            currentSongId: nil,
                            currentSongSeconds: nil
                        )
                    }
                }
            }
        }
    }
}
