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

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.haptic = haptic
        services.currentPlaylist = playlist
        services.player = player
        services.download = download
        services.audioSession = audioSession
    }

    @Test("mutating the state presents the state")
    func state() {
        let songs = [SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)]
        subject.state.songs = songs
        #expect(presenter.statePresented?.songs == songs)
    }

    @Test("receive initialData: sends `getSongsFor` to request maker, sets state `songs`")
    func receiveInitialData() async {
        playlist.list = [SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.songs == [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)])
    }

    @Test("receive tapped: calls current playlist buildSequence, calls haptic success, sets audio session active")
    func receiveTapped() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        let song2 = SubsonicSong(id: "2", title: "Title2", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        playlist.sequenceToReturn = [song, song2]
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["buildSequence(startingWith:)"])
        #expect(haptic.methodsCalled == ["success()"])
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
    }

    @Test("receive tapped: doesn't proceed further if playlist buildSequence returned list is empty")
    func receiveTappedNoSequence() async {
        playlist.sequenceToReturn = []
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["buildSequence(startingWith:)"])
        #expect(haptic.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
    }

    @Test("receive tapped: given a sequence, calls download and play for the first one, download and playNext for the rest")
    func receiveTappedDownloadAndPlay() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        let song2 = SubsonicSong(id: "2", title: "Title2", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        let song3 = SubsonicSong(id: "3", title: "Title3", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        playlist.sequenceToReturn = [song, song2, song3]
        await subject.receive(.tapped(song))
        #expect(download.methodsCalled == ["download(song:)", "download(song:)", "download(song:)"])
        #expect(player.methodsCalled == ["play(url:song:)", "playNext(url:song:)", "playNext(url:song:)"])
    }


}
