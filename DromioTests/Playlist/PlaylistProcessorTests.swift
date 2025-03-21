@testable import Dromio
import Testing
import WaitWhile
import Foundation

@MainActor
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

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.haptic = haptic
        services.currentPlaylist = playlist
        services.player = player
        services.download = download
        services.networker = networker
    }

    @Test("mutating the state presents the state")
    func state() {
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
        #expect(presenter.statePresented?.songs == songs)
    }

    @Test("mutating the state with `noPresentation` doesn't present the state")
    func stateNoPresentation() {
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
        subject.noPresentation = true
        subject.state.songs = songs
        #expect(presenter.statePresented == nil)
        #expect(subject.noPresentation == false)
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
        #expect(subject.downloadPipeline == nil)
        #expect(subject.playerPipeline == nil)
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
                downloaded: nil
            )]
        )
        #expect(subject.downloadPipeline != nil)
        #expect(subject.playerPipeline != nil)
        networker.progress.send((id: "2", fraction: 0.5))
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived[0] == .progress("2", 0.5))
        player.currentSongIdPublisher.send("10")
        #expect(subject.state.currentSongId == "10")
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
                downloaded: nil
            )]
        )
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

    @Test("receive jukeboxButton: toggles state jukeboxMode")
    func receiveJukebox() async {
        #expect(!subject.state.jukeboxMode)
        await subject.receive(.jukeboxButton)
        #expect(subject.state.jukeboxMode)
        await subject.receive(.jukeboxButton)
        #expect(!subject.state.jukeboxMode)
    }

    @Test("receive tapped: calls haptic, sends .deselectAll")
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
    }

    @Test("receive tapped: calls stream, play, download for the first; download, playNext for the rest; marks songs downloaded")
    func receiveTappedDownloadAndPlay() async {
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
        await #expect(download.methodsCalled == ["downloadedURL(for:)", "download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
        #expect(player.urls.map { $0.scheme } == ["http", "file", "file"])
        #expect(subject.state.songs.filter { $0.downloaded == true }.count == 3)
    }

    @Test("receive tapped: if first is already downloaded, calls play, download for the first; download, playNext for the rest")
    func receiveTappedDownloadAndPlayNoStream() async {
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
        await #expect(download.methodsCalled == ["downloadedURL(for:)", "download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
        #expect(player.urls.map { $0.scheme } == ["file", "file", "file"])
        #expect(subject.state.songs.filter { $0.downloaded == true }.count == 3)
    }

    @Test("receive tapped: doesn't proceed further if song is not in state")
    func receiveTappedNoSequence() async {
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
        await #expect(download.methodsCalled.isEmpty)
        #expect(player.methodsCalled.isEmpty)
    }

    @Test("receive tapped: in jukebox mode tells the jukebox stop, clear, add each song, start")
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
        #expect(playlist.methodsCalled == ["clear()"])
        #expect(player.methodsCalled == ["clear()"])
        await #expect(download.methodsCalled == ["clear()"])
        #expect(subject.state.songs.isEmpty)
        await #while(coordinator.methodsCalled.isEmpty)
        #expect(coordinator.methodsCalled == ["popPlaylist()"])
    }

    @Test("receive clear: in jukebox mode tells request maker to send jukebox control stop and clear")
    func clearJukeboxMode() async {
        subject.state.jukeboxMode = true
        await subject.receive(.clear)
        #expect(playlist.methodsCalled.isEmpty)
        #expect((await download.methodsCalled).isEmpty)
        #expect(coordinator.methodsCalled.isEmpty)
        #expect(requestMaker.methodsCalled == ["jukebox(action:songId:)", "jukebox(action:songId:)"])
        #expect(requestMaker.actions == [.stop, .clear])
    }
}
