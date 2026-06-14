@testable import Dromio
import Testing
import WaitWhile
import Foundation

struct PlaylistProcessorTests {
    let subject = PlaylistProcessor()
    let presenter = MockReceiverPresenter<PlaylistEffect, PlaylistState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()
    let haptic = MockHaptic()
    let playlist = MockPlaylist()
    let player = MockPlayer()
    let download = MockDownload()
    let networker = MockNetworker()
    let persistence = MockPersistence()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.haptic = haptic
        services.currentPlaylist = playlist
        services.player = player
        services.download = download
        services.networker = networker
        services.persistence = persistence
    }

    @Test("receive clear: tells the current playlist, player, and download to clear, sets the state, call popPlaylist")
    func clear() async {
        let songs = [SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        subject.state.songs = songs
        await subject.receive(.clear)
        #expect(haptic.methodsCalled == ["impact()"])
        #expect(playlist.methodsCalled == ["clear()"])
        #expect(player.methodsCalled == ["clear()"])
        #expect(networker.methodsCalled == ["clear()"])
        #expect(download.methodsCalled == ["clear()"])
        #expect(presenter.statePresented?.songs == [])
        await #while(coordinator.methodsCalled.isEmpty)
        #expect(coordinator.methodsCalled == ["popPlaylist()"])
    }

    @Test("receive clear: in jukebox mode tells request maker to send jukebox control stop and clear")
    func clearJukeboxMode() async {
        subject.state.jukeboxMode = true
        await subject.receive(.clear)
        #expect(haptic.methodsCalled == ["impact()"])
        #expect(playlist.methodsCalled.isEmpty)
        #expect(download.methodsCalled.isEmpty)
        #expect(coordinator.methodsCalled.isEmpty)
        #expect(requestMaker.methodsCalled == ["jukebox(action:songId:)", "jukebox(action:songId:)"])
        #expect(requestMaker.actions == [.stop, .clear])
    }

    @Test("receive delete: clears player, tells download and current playlist to delete song, presents with state animate true")
    func receiveDelete() async {
        subject.state.songs = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.delete(1))
        #expect(player.methodsCalled.last == "clear()")
        #expect(networker.methodsCalled == ["clear()"])
        #expect(download.methodsCalled.last == "delete(song:)")
        #expect(download.song?.id == "2")
        #expect(playlist.methodsCalled.last == "delete(song:)")
        #expect(playlist.song?.id == "2")
        #expect(presenter.statePresented?.animate == true)
        #expect(subject.state.animate == false)
    }

    @Test("receive delete: sets state `songs` from current playlist")
    func receiveDeleteSongs() async {
        subject.state.songs = [SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        playlist.list = [SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.delete(0))
        #expect(
            presenter.statePresented?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: false
            )]
        )
        #expect(presenter.statePresented?.animate == true)
        #expect(subject.state.animate == false)
    }

    @Test("receive delete: bad row, does nothing")
    func receiveDeleteBadRow() async {
        subject.state.songs = [SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        playlist.list = [SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.delete(2))
        #expect(presenter.statePresented == nil)
        #expect(player.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.isEmpty)
        #expect(playlist.methodsCalled.isEmpty)
    }

    @Test("receive delete: if the Download says this song is downloaded, marks it as downloaded in the state")
    func receiveDeleteDownloaded() async {
        subject.state.songs = [
            .init(
                id: "3",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil
            )
        ]
        download.bools["1"] = true
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.delete(0))
        #expect(
            subject.state.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // *
            ), .init(
                id: "2",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: false
            )]
        )
    }

    @Test("receive delete: presents only once while looping thru downloads")
    func receiveDeleteDownloadedOnePresentation() async {
        subject.state.songs = [SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        download.bools["1"] = true
        download.bools["2"] = true
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.delete(0))
        #expect(presenter.statesPresented.count == 1)
        #expect(
            presenter.statesPresented.first?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // *
            ), .init(
                id: "2",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // * got them both in one presentation
            )]
        )
    }

    @Test("receive delete: if offline mode, filters out undownloaded songs, marks remaining songs downloaded")
    func receiveDeleteOfflineMode() async {
        subject.state.songs = [SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        download.bools["1"] = true
        download.bools["2"] = false
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        subject.state.offlineMode = true
        await subject.receive(.delete(0))
        #expect(
            presenter.statePresented?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true
            )]
        )
    }

    @Test("receive editButton: clears player, toggle state editMode; if turned editMode off, presents twice")
    func editButton() async throws {
        await subject.receive(.editButton)
        #expect(player.methodsCalled == ["clear()"])
        #expect(networker.methodsCalled == ["clear()"])
        #expect(presenter.statePresented?.editMode == true)
        #expect(presenter.statesPresented.count == 1)
        #expect(presenter.statesPresented[0].updateTableView == false)
        presenter.statesPresented = []
        await subject.receive(.editButton)
        #expect(presenter.statePresented?.editMode == false)
        #expect(presenter.statesPresented.count == 2)
        #expect(presenter.statesPresented[0].updateTableView == false)
        #expect(presenter.statesPresented[1].updateTableView == true)
    }

    @Test("receive initialData: sets state `songs`, sets pipelines, pipelines work")
    func receiveInitialData() async {
        playlist.list = [SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        #expect(subject.task1 == nil)
        #expect(subject.task2 == nil)
        #expect(subject.task3 == nil)
        await subject.receive(.initialData)
        #expect(
            presenter.statePresented?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: false
            )]
        )
        /// there are three tasks
        #expect(subject.task1 != nil)
        #expect(subject.task2 != nil)
        #expect(subject.task3 != nil)
        /// task1 responds to networker progress by sending .progress to presenter
        networker.progress = (id: "2", fraction: 0.5)
        await #while(!presenter.thingsReceived.contains(.progress("2", 0.5)))
        #expect(presenter.thingsReceived.contains(.progress("2", 0.5)))
        /// task2 responds to player current song id by presenting state to presenter;
        /// if there is a current song id (i.e. not nil), state resumable song is nil
        /// also scrobbles
        presenter.statePresented = nil
        subject.state.resumableSong = .init(id: "yoho", seconds: 100)
        player.currentSongIdPublisher = "10"
        await #while(presenter.statePresented == nil)
        #expect(presenter.statePresented?.currentSongId == "10")
        #expect(presenter.statePresented?.resumableSong == nil)
        await #while(requestMaker.methodsCalled.isEmpty)
        #expect(requestMaker.methodsCalled.contains("scrobble(songId:)"))
        #expect(requestMaker.songId == "10")
        /// task3 responds to player state by sending playerState to presenter
        /// also calls persistence saveCurrentPaused to paused song or nil
        /// case 1: .playing - nilifies persistence current song paused
        persistence.currentSongId = "yoho"
        persistence.currentSongSeconds = 100
        presenter.thingsReceived = []
        player.playerStatePublisher = .playing
        await #while(!presenter.thingsReceived.contains(.playerState(.playing)))
        #expect(presenter.thingsReceived.contains(.playerState(.playing)))
        #expect(persistence.methodsCalled.last == "saveCurrentPaused(currentSongId:currentSongSeconds:)")
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
        /// case 2: .empty - does nothing to persistence current song paused
        persistence.currentSongId = "yoho"
        persistence.currentSongSeconds = 100
        presenter.thingsReceived = []
        player.playerStatePublisher = .empty
        await #while(!presenter.thingsReceived.contains(.playerState(.empty)))
        #expect(presenter.thingsReceived.contains(.playerState(.empty)))
        #expect(persistence.methodsCalled.last == "saveCurrentPaused(currentSongId:currentSongSeconds:)")
        #expect(persistence.currentSongId == "yoho")
        #expect(persistence.currentSongSeconds == 100)
        /// case 3: .paused, when player current song id exists - sets persistence song paused
        persistence.currentSongId = nil
        persistence.currentSongSeconds = nil
        presenter.thingsReceived = []
        player.currentSongIdPublisher = "yoho"
        player.playerStatePublisher = .paused(at: 200)
        await #while(!presenter.thingsReceived.contains(.playerState(.paused(at: 200))))
        #expect(presenter.thingsReceived.contains(.playerState(.paused(at: 200))))
        #expect(persistence.methodsCalled.last == "saveCurrentPaused(currentSongId:currentSongSeconds:)")
        #expect(persistence.currentSongId == "yoho")
        #expect(persistence.currentSongSeconds == 200)
        /// case 3b: .paused, when player current song id is nil (shouldn't happen but test logic anyway)
        persistence.currentSongId = "yoho"
        persistence.currentSongSeconds = 100
        presenter.thingsReceived = []
        player.currentSongIdPublisher = nil
        player.playerStatePublisher = .paused(at: 300)
        await #while(!presenter.thingsReceived.contains(.playerState(.paused(at: 300))))
        #expect(presenter.thingsReceived.contains(.playerState(.paused(at: 300))))
        #expect(persistence.methodsCalled.last == "saveCurrentPaused(currentSongId:currentSongSeconds:)")
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
    }

    @Test("receive initialData: current song id and player state pipelines remove duplicates")
    func removeDuplicates() async {
        await subject.receive(.initialData)
        try? await Task.sleep(for: .seconds(0.2))
        presenter.statesPresented = []
        player.currentSongIdPublisher = "10"
        try? await Task.sleep(for: .seconds(0.2))
        player.currentSongIdPublisher = "10"
        try? await Task.sleep(for: .seconds(0.2))
        let relevantStates = presenter.statesPresented.filter { $0.currentSongId == "10" }
        #expect(relevantStates.count == 1)
        await #while(presenter.thingsReceived.isEmpty)
        presenter.thingsReceived = []
        player.playerStatePublisher = .playing
        player.playerStatePublisher = .playing
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived.count == 1)
    }

    @Test("receive initialData: if the Download says this song is downloaded, marks it as downloaded in the state")
    func receiveInitialDataDownloaded() async {
        download.bools["1"] = true
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.initialData)
        #expect(
            subject.state.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // *
            ), .init(
                id: "2",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: false
            )]
        )
        #expect(playlist.methodsCalled.contains("setList(_:)"))
        #expect(playlist.list == subject.state.songs) // still in sync
    }

    @Test("receive initialData: presents only once while looping thru downloads")
    func receiveInitialDataDownloadedOnePresentation() async {
        download.bools["1"] = true
        download.bools["2"] = true
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        #expect(presenter.statesPresented.count == 0)
        await subject.receive(.initialData)
        #expect(
            presenter.statesPresented.first?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // *
            ), .init(
                id: "2",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true // * got them both in one presentation
            )]
        )
    }

    @Test("receive initialData: if offline mode, filters out undownloaded songs, marks remaining songs downloaded")
    func receiveInitialDataOfflineMode() async {
        download.bools["1"] = true
        download.bools["2"] = false
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        subject.state.offlineMode = true
        await subject.receive(.initialData)
        #expect(
            presenter.statesPresented.first?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil,
                downloaded: true
            )]
        )
        #expect(playlist.methodsCalled.contains("setList(_:)"))
        #expect(playlist.list == subject.state.songs) // still in sync
    }

    @Test("receive initialData: checks for resumability and sets the state accordingly")
    func receiveInitialDataResumability() async {
        // We are resumable if (1) there are current paused id and paused seconds in persistence,
        // (2) that song is in the state's `songs`,
        // and (3) that song and all subsequent songs in the state's `songs` are already downloaded.
        persistence.currentSongId = "1"
        persistence.currentSongSeconds = 100
        download.bools = ["1": true, "2": true]
        playlist.list = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.resumableSong == .init(id: "1", seconds: 100))
        // now let's falsify the conditions one at a time
        persistence.currentSongId = nil
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        //
        persistence.currentSongId = "1"
        persistence.currentSongSeconds = nil
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        //
        persistence.currentSongSeconds = 100
        persistence.currentSongId = "3"
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        //
        persistence.currentSongSeconds = 100
        persistence.currentSongId = "1"
        download.bools = ["1": true, "2": false]
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
    }

    @Test("receive jukeboxButton: toggles state jukeboxMode, call haptic")
    func receiveJukebox() async {
        #expect(subject.state.jukeboxMode == false)
        await subject.receive(.jukeboxButton)
        #expect(presenter.statePresented?.jukeboxMode == true)
        #expect(haptic.methodsCalled == ["impact()"])
        await subject.receive(.jukeboxButton)
        #expect(presenter.statePresented?.jukeboxMode == false)
        #expect(haptic.methodsCalled == ["impact()", "impact()"])
    }

    @Test("receive move: tells playlist to move, does move as specified")
    func move() async throws {
        subject.state.songs = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        await subject.receive(.move(from: 1, to: 0))
        #expect(playlist.methodsCalled == ["move(from:to:)"])
        #expect(playlist.fromRow == 1)
        #expect(playlist.toRow == 0)
        #expect(presenter.statePresented?.songs == [.init(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )])
    }

    @Test("receive playPause: tells the player to playPause")
    func playpause() async {
        await subject.receive(.playPause)
        #expect(haptic.methodsCalled == ["impact()"])
        #expect(player.methodsCalled == ["playPause()"])
    }

    @Test("receive resume: if resumable, calls haptic, clears player and networker, sends .deselectAll")
    func receiveResume() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2]
        download.bools = ["1": true, "2": true]
        subject.state.resumableSong = .init(id: "1", seconds: 100)
        await subject.receive(.resume)
        #expect(haptic.methodsCalled == ["success()"])
        #expect(presenter.thingsReceived[0] == .deselectAll)
        #expect(player.methodsCalled.first == "clear()")
        #expect(networker.methodsCalled.first == "clear()")
    }

    @Test("receive resume: if not resumable, resumable song becomes nil in state and persistence, presents")
    func receiveResumeNotResumable() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2]
        download.bools = ["1": true, "2": false] // *
        subject.state.resumableSong = .init(id: "1", seconds: 100)
        persistence.currentSongId = "yoho"
        persistence.currentSongSeconds = 100
        await subject.receive(.resume)
        #expect(haptic.methodsCalled.isEmpty)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(player.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.isEmpty)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        #expect(persistence.methodsCalled == ["saveCurrentPaused(currentSongId:currentSongSeconds:)"])
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
        //
        persistence.methodsCalled = []
        download.bools = ["1": true, "2": true]
        presenter.statesPresented = []
        subject.state.resumableSong = .init(id: "3", seconds: 100)
        await subject.receive(.resume)
        #expect(haptic.methodsCalled.isEmpty)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(player.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.isEmpty)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        #expect(persistence.methodsCalled == ["saveCurrentPaused(currentSongId:currentSongSeconds:)"])
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
        //
        persistence.methodsCalled = []
        presenter.statesPresented = []
        subject.state.resumableSong = nil
        await subject.receive(.resume)
        #expect(haptic.methodsCalled.isEmpty)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(player.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.isEmpty)
        #expect(presenter.statesPresented.last?.resumableSong == nil)
        #expect(persistence.methodsCalled == ["saveCurrentPaused(currentSongId:currentSongSeconds:)"])
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
    }

    @Test("receive resume: calls downloadedURL for all songs, calls play seconds for first, playNext for rest")
    func resumePlays() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2]
        download.bools = ["1": true, "2": true]
        subject.state.resumableSong = .init(id: "1", seconds: 100)
        await subject.receive(.resume)
        #expect(download.methodsCalled == ["downloadedURL(for:)", "downloadedURL(for:)"])
        #expect(player.methodsCalled == ["clear()", "play(url:song:seconds:)", "playNext(url:song:)"])
        #expect(player.urls.map { $0.scheme } == ["file", "file"])
        #expect(player.songs == [song, song2])
        #expect(player.seconds == 100)
    }

    @Test("receive resume: when resumable and plays, resumable song becomes nil in state and persistence, presents")
    func receiveResumeNilifies() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2]
        download.bools = ["1": true, "2": true]
        subject.state.resumableSong = .init(id: "1", seconds: 100)
        await subject.receive(.resume)
        #expect(presenter.statesPresented.count == 1)
        #expect(presenter.statesPresented[0].resumableSong == nil)
        #expect(persistence.methodsCalled == ["saveCurrentPaused(currentSongId:currentSongSeconds:)"])
        #expect(persistence.currentSongId == nil)
        #expect(persistence.currentSongSeconds == nil)
    }

    @Test("receive tapped: calls haptic, clears player and networker, sends .deselectAll", .mockBackgroundTask)
    func receiveTapped() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2]
        await subject.receive(.tapped(song))
        #expect(haptic.methodsCalled == ["success()"])
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived[0] == .deselectAll)
        #expect(player.methodsCalled.first == "clear()")
        #expect(networker.methodsCalled.first == "clear()")
    }

    @Test("receive tapped: calls stream, play, download for the first; download, playNext for the rest; marks songs downloaded", .mockBackgroundTask)
    func receiveTappedDownloadAndPlay() async throws {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song3 = SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2, song3]
        await subject.receive(.tapped(song))
        #expect(requestMaker.methodsCalled == ["stream(songId:)"])
        #expect(download.methodsCalled == ["downloadedURL(for:)", "download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["clear()", "play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
        #expect(player.urls.map { $0.scheme } == ["http", "file", "file"])
        #expect(player.songs == [song, song2, song3])
        #expect(presenter.statePresented?.songs.filter { $0.downloaded == true }.count == 3)
        #expect(try operatedOnBackgroundTask() == 3)
    }

    @Test("receive tapped: if first is already downloaded, calls play, download for the first; download, playNext for the rest", .mockBackgroundTask)
    func receiveTappedDownloadAndPlayNoStream() async throws {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song3 = SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        download.bools = ["1": true, "2": true, "3": false]
        subject.state.songs = [song, song2, song3]
        await subject.receive(.tapped(song))
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(download.methodsCalled == ["downloadedURL(for:)", "download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["clear()", "play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
        #expect(player.urls.map { $0.scheme } == ["file", "file", "file"])
        #expect(player.songs == [song, song2, song3])
        #expect(presenter.statePresented?.songs.filter { $0.downloaded == true }.count == 3)
        #expect(try operatedOnBackgroundTask() == 3)
    }

    @Test("receive tapped: if all in sequence already downloaded, no presentation", .mockBackgroundTask)
    func receiveTappedDownloadAndPlayNoStreamNoPresentation() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil,
            downloaded: true
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil,
            downloaded: true
        )
        let song3 = SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil,
            downloaded: true
        )
        download.bools = ["1": true, "2": true, "3": false]
        subject.state.songs = [song, song2, song3]
        presenter.statePresented = nil
        await subject.receive(.tapped(song))
        #expect(presenter.statePresented == nil)
    }

    @Test("receive tapped: doesn't proceed further if song is not in state", .mockBackgroundTask)
    func receiveTappedNoSequence() async throws {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song3 = SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song2, song3]
        await subject.receive(.tapped(song))
        #expect(haptic.methodsCalled.isEmpty)
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(download.methodsCalled.isEmpty)
        #expect(player.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.isEmpty)
        let mockBackgroundTaskOperationMaker = try #require(services.backgroundTaskOperationMaker as? MockBackgroundTaskOperationMaker)
        #expect(mockBackgroundTaskOperationMaker.mockBackgroundTaskOperation == nil)
    }

    @Test("receive tapped: in jukebox mode tells the jukebox stop, clear, add each song, start", .mockBackgroundTask)
    func receiveTappedJukeboxMode() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song3 = SubsonicSong(
            id: "3",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.state.songs = [song, song2, song3]
        subject.state.jukeboxMode = true
        await subject.receive(.tapped(song))
        #expect(requestMaker.methodsCalled == ["jukebox(action:songId:)", "jukebox(action:songId:)", "jukebox(action:songId:)", "jukebox(action:songId:)", "jukebox(action:songId:)", "jukebox(action:songId:)"])
        #expect(requestMaker.actions == [.stop, .clear, .add, .add, .add, .start])
        #expect(requestMaker.songIds == [nil, nil, "1", "2", "3", nil])
    }

    func operatedOnBackgroundTask() throws -> Int {
        let mockBackgroundTaskOperationMaker = try #require(services.backgroundTaskOperationMaker as? MockBackgroundTaskOperationMaker)
        let mockBackgroundTaskOperation = try #require(
            mockBackgroundTaskOperationMaker.mockBackgroundTaskOperation as? MockBackgroundTaskOperation<Void>
        )
        #expect(mockBackgroundTaskOperation.methodsCalled == ["start()"])
        return mockBackgroundTaskOperationMaker.timesCalled
    }
}
