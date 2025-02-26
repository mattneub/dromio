@testable import Dromio
import Testing
import WaitWhile

@MainActor
struct AlbumProcessorTests {
    let subject = AlbumProcessor()
    let presenter = MockReceiverPresenter<AlbumEffect, AlbumState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()
    let haptic = MockHaptic()
    let playlist = MockPlaylist()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.haptic = haptic
        services.currentPlaylist = playlist
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albumId = "1"
        #expect(presenter.statePresented?.albumId == "1")
    }

    @Test("receive initialData: sends `getSongsFor` to request maker, sets state `songs`")
    func receiveInitialData() async {
        requestMaker.songList = [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)]
        subject.state.albumId = "2"
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getSongsFor(albumId:)"])
        #expect(requestMaker.albumId == "2")
        #expect(presenter.statePresented?.songs == [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)])
    }

    @Test("receive tapped: appends to current playlist, calls haptic success, sends deselectAll effect")
    func receiveTapped() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["append(_:)"])
        #expect(haptic.methodsCalled == ["success()"])
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived == [.deselectAll])
    }

    @Test("receive tapped: receiving error from append calls haptic failure, sends deselectAll effect")
    func receiveTappedFailure() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)
        playlist.errorToThrow = PlaylistError.songAlreadyInList
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["append(_:)"])
        #expect(haptic.methodsCalled == ["failure()"])
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived == [.deselectAll])
    }

    @Test("receive showPlaylist: tells coordinator to showPlaylist")
    func showPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }
}
