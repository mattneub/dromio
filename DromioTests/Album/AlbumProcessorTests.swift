@testable import Dromio
import Testing

@MainActor
struct AlbumProcessorTests {
    let subject = AlbumProcessor()
    let presenter = MockReceiverPresenter<Void, AlbumState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albumId = "1"
        #expect(presenter.statePresented?.albumId == "1")
    }

    @Test("receive initialData: sends `getSongsFor` to request maker, sets state `songs`")
    func receiveInitialData() async {
        requestMaker.songList = [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")]
        subject.state.albumId = "2"
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getSongsFor(albumId:)"])
        #expect(requestMaker.albumId == "2")
        #expect(presenter.statePresented?.songs == [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")])
    }
}
