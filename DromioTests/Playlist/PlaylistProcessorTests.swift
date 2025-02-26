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

    @Test("receive tapped: appends to current playlist, calls haptic success, sends deselectAll effect")
    func receiveTapped() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        let url = URL(string: "file://wherever")!
        download.urlToReturn = url
        await subject.receive(.tapped(song))
        #expect(haptic.methodsCalled == ["success()"])
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(download.methodsCalled == ["download(song:)"])
        #expect(download.song == song)
        #expect(player.methodsCalled == ["play(url:song:)"])
        #expect(player.song == song)
        #expect(player.url == url)
    }
}
