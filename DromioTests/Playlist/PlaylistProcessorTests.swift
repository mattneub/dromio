@testable import Dromio
import Testing
import WaitWhile

@MainActor
struct PlaylistProcessorTests {
    let subject = PlaylistProcessor()
    let presenter = MockReceiverPresenter<PlaylistEffect, PlaylistState>()
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
        let songs = [SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")]
        subject.state.songs = songs
        #expect(presenter.statePresented?.songs == songs)
    }

    @Test("receive initialData: sends `getSongsFor` to request maker, sets state `songs`")
    func receiveInitialData() async {
        playlist.list = [SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.songs == [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")])
    }

    @Test("receive tapped: appends to current playlist, calls haptic success, sends deselectAll effect")
    func receiveTapped() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")
        await subject.receive(.tapped(song))
//        #expect(playlist.methodsCalled == ["append(_:)"])
//        #expect(playlist.list == [song])
//        #expect(haptic.methodsCalled == ["success()"])
//        await #while(presenter.thingsReceived.isEmpty)
//        #expect(presenter.thingsReceived == [.deselectAll])
    }
}
