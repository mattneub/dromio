@testable import Dromio
import Testing

@MainActor
struct AlbumsProcessorTests {
    let subject = AlbumsProcessor()
    let presenter = MockReceiverPresenter<Void, AlbumsState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albums.append(.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
        #expect(presenter.statePresented?.albums.first == .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
    }

    @Test("receive initialData: sends `getAlbumList` to request maker, sets state `albums`")
    func receiveInitialData() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("showAlbum: sends `showAlbum` to coordinator, with info from specified album")
    func showAlbum() async {
        subject.state.albums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.showAlbum(albumId: "1"))
        #expect(coordinator.methodsCalled == ["showAlbum(albumId:songCount:title:)"])
        #expect(coordinator.albumId == "1")
        #expect(coordinator.songCount == 30)
        #expect(coordinator.title == "Yoho")
    }

    @Test("receive showPlaylist: tells coordinator to showPlaylist")
    func showPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }
}
