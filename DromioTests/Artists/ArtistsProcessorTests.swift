@testable import Dromio
import Testing

@MainActor
struct ArtistsProcessorTests {
    let subject = ArtistsProcessor()
    let presenter = MockReceiverPresenter<Void, ArtistsState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.artists.append(.init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil))
        #expect(presenter.statePresented?.artists.first == .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil))
    }

    @Test("receive allArtists: sends `getArtists` to request maker, filters, sets state")
    func receiveAllArtists() async {
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.allArtists)
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(subject.state.listType == .allArtists)
        #expect(subject.state.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive composers: sends `getArtists` to request maker, filters, sets state")
    func receiveComposers() async {
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.composers)
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(subject.state.listType == .composers)
        #expect(subject.state.artists == [.init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil)])
    }

    @Test("receive albums: sends dismissArtists to coordinator")
    func receiveAlbums() async {
        await subject.receive(.albums)
        #expect(coordinator.methodsCalled.last == "dismissArtists()")
    }

    @Test("receive showPlaylist: tells coordinator to showPlaylist")
    func receiveShowPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }

    @Test("receive showAlbums: tells coordinator to show albums")
    func receiveShowAlbums() async {
        await subject.receive(.showAlbums(artistId: "1"))
        #expect(coordinator.methodsCalled.last == "showAlbumsForArtist(state:)")
        #expect(coordinator.albumsState == .init(listType: .albumsForArtist(id: "1"), albums: []))
    }
}
