@testable import Dromio
import Testing

@MainActor
struct ArtistsProcessorTests {
    let subject = ArtistsProcessor()
    let presenter = MockReceiverPresenter<ArtistsEffect, ArtistsState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        caches.allArtists = nil
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.artists.append(.init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil))
        #expect(presenter.statePresented?.artists.first == .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil))
    }

    @Test("receive albums: sends dismissArtists to coordinator")
    func receiveAlbums() async {
        await subject.receive(.albums)
        #expect(coordinator.methodsCalled.last == "dismissArtists()")
    }

    @Test("receive allArtists: sends tearDown effect, sends `getArtists` to request maker, filters, sets state")
    func receiveAllArtists() async {
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.allArtists)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(subject.state.listType == .allArtists)
        #expect(subject.state.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive allArtists: gets list from cache if it exists, sends effect, filters, sets state")
    func receiveAllArtistsCached() async {
        caches.allArtists = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        requestMaker.artistList = []
        await subject.receive(.allArtists)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(subject.state.listType == .allArtists)
        #expect(subject.state.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive composers: sends effect, sends `getArtists` to request maker, filters, sets state")
    func receiveComposers() async {
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.composers)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(subject.state.listType == .composers)
        #expect(subject.state.artists == [.init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil)])
    }

    @Test("receive composers: gets list from cache if it exists, sends effect, filters, sets state")
    func receiveComposersCached() async {
        caches.allArtists = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        requestMaker.artistList = []
        await subject.receive(.composers)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(subject.state.listType == .composers)
        #expect(subject.state.artists == [.init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil)])
    }

    @Test("receiver server: tell coordinator to dismissToPing")
    func receiveServer() async {
        await subject.receive(.server)
        #expect(coordinator.methodsCalled.last == "dismissToPing()")
    }

    @Test("receive showPlaylist: sends no effect, tells coordinator to showPlaylist")
    func receiveShowPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(presenter.thingsReceived == [])
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }

    @Test("receive showAlbums: for .allArtists sends no effect, tells coordinator to show albums with source artists")
    func receiveShowAlbumsAllArtists() async {
        subject.state.listType = .allArtists
        await subject.receive(.showAlbums(artistId: "1"))
        #expect(coordinator.methodsCalled.last == "showAlbumsForArtist(state:)")
        #expect(presenter.thingsReceived == [])
        #expect(coordinator.albumsState == .init(listType: .albumsForArtist(id: "1", source: .artists), albums: []))
    }

    @Test("receive showAlbums: for .composers sends no effect, tells coordinator to show albums with source composers with correct name")
    func receiveShowAlbumsAllComposers() async {
        subject.state.listType = .composers
        subject.state.artists = [.init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        await subject.receive(.showAlbums(artistId: "1"))
        #expect(coordinator.methodsCalled.last == "showAlbumsForArtist(state:)")
        #expect(presenter.thingsReceived == [])
        #expect(coordinator.albumsState == .init(listType: .albumsForArtist(id: "1", source: .composers(name: "Me")), albums: []))
    }

    @Test("receive showAlbums: for .composers sends no effect, if no composer with given id just stops")
    func receiveShowAlbumsAllComposersNoMatch() async {
        subject.state.listType = .composers
        subject.state.artists = [.init(id: "2", name: "Me", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        await subject.receive(.showAlbums(artistId: "1"))
        #expect(coordinator.methodsCalled.isEmpty)
        #expect(presenter.thingsReceived == [])
    }

    @Test("receive viewDidAppear: sends `setUpSearcher` effect")
    func receiveViewDidAppear() async {
        await subject.receive(.viewDidAppear)
        #expect(presenter.thingsReceived == [.setUpSearcher])
    }
}
