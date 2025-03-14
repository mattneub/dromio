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
    let audioSession = MockAudioSession()
    let networker = MockNetworker()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.haptic = haptic
        services.currentPlaylist = playlist
        services.player = player
        services.download = download
        services.audioSession = audioSession
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
            duration: nil
        )]
        subject.state.songs = songs
        #expect(presenter.statePresented?.songs == songs)
    }

    @Test("receive initialData: sets state `songs`, sets pipeline which forwards .progress to the presenter")
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
            duration: nil
        )]
        #expect(subject.pipeline == nil)
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
                downloaded: false // *
            )]
        )
        #expect(subject.pipeline != nil)
        networker.progress.send((id: "2", fraction: 0.5))
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived[0] == .progress("2", 0.5))
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
            duration: nil
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
            duration: nil
        )]
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
                downloaded: false // *
            )]
        )
    }

    @Test("receive tapped: calls playlist buildSequence, calls haptic, sets audio session active, sends .deselectAll")
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
            duration: nil
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
            duration: nil
        )
        playlist.sequenceToReturn = [song, song2]
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["buildSequence(startingWith:)"])
        #expect(haptic.methodsCalled == ["success()"])
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
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
            duration: nil
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
            duration: nil
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
            duration: nil
        )
        playlist.sequenceToReturn = [song, song2, song3]
        subject.state.songs = [song, song2, song3]
        await subject.receive(.tapped(song))
        #expect(requestMaker.methodsCalled == ["stream(songId:)"])
        #expect(requestMaker.songId == "1")
        await #expect(download.methodsCalled == ["download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
        #expect(subject.state.songs.filter { $0.downloaded == true }.count == 3)
    }

    @Test("receive tapped: doesn't proceed further if playlist buildSequence returned list is empty")
    func receiveTappedNoSequence() async {
        playlist.sequenceToReturn = []
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
            duration: nil
        )
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["buildSequence(startingWith:)"])
        #expect(haptic.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(requestMaker.methodsCalled.isEmpty)
        await #expect(download.methodsCalled.isEmpty)
        #expect(player.methodsCalled.isEmpty)
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
            duration: nil
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
}
