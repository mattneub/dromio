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
        caches.albumsList = nil
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albums.append(.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
        #expect(presenter.statePresented?.albums.first == .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
    }

    @Test("receive initialData: if listType is .albumsForArtist, sends getAlbumsFor with id to request maker, sets state")
    func receiveInitialDataForArtist() async {
        subject.state.listType = .albumsForArtist(id: "1")
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumsFor(artistId:)"])
        #expect(requestMaker.artistId == "1")
        #expect(subject.state.listType == .albumsForArtist(id: "1"))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive initialData: if listType is .allAlbums behaves exactly as receiving .allAlbums")
    func receiveInitialDataAllAlbums() async {
        subject.state.listType = .allAlbums
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(subject.state.listType == .allAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive allAlbums: sends `getAlbumList` to request maker, sets state")
    func receiveAllAlbums() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.allAlbums)
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(subject.state.listType == .allAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive randomAlbums: sends `getAlbumList` to request maker, sets state")
    func receiveRandomAlbums() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.randomAlbums)
        #expect(requestMaker.methodsCalled == ["getAlbumsRandom()"])
        #expect(subject.state.listType == .randomAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("showAlbum: sends `showAlbum` to coordinator, with info from specified album")
    func showAlbum() async {
        subject.state.albums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.showAlbum(albumId: "1"))
        #expect(coordinator.methodsCalled == ["showAlbum(albumId:title:)"])
        #expect(coordinator.albumId == "1")
        #expect(coordinator.title == "Yoho")
    }

    @Test("receive artists: tell coordinator to showArtists")
    func showArtists() async {
        await subject.receive(.artists)
        #expect(coordinator.methodsCalled.last == "showArtists()")
    }

    @Test("receive showPlaylist: tells coordinator to showPlaylist")
    func showPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }
}
