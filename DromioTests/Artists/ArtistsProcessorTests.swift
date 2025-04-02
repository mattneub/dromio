@testable import Dromio
import Testing

@MainActor
struct ArtistsProcessorTests {
    let subject = ArtistsProcessor()
    let presenter = MockAsyncReceiverPresenter<ArtistsEffect, ArtistsState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        caches.allArtists = nil
    }

    @Test("receive albums: sends dismissArtists to coordinator")
    func receiveAlbums() async {
        await subject.receive(.albums)
        #expect(coordinator.methodsCalled.last == "dismissArtists()")
    }

    @Test("receive allArtists: starts by presenting spinner animation")
    func receiveAllArtistsStart() async {
        subject.state.animateSpinner = false
        #expect(presenter.statePresented == nil)
        await subject.receive(.allArtists)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
    }

    @Test("receive allArtists: sends `getArtists` to request maker, filters, sets state, turns off spinner, sends searcher/scroll effects")
    func receiveAllArtists() async {
        subject.state.animateSpinner = true
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.allArtists)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(presenter.statePresented?.listType == .allArtists)
        #expect(presenter.statePresented?.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive allArtists: gets list from cache if it exists, filters, sets state, turns off spinner, sends effects")
    func receiveAllArtistsCached() async {
        subject.state.animateSpinner = true
        caches.allArtists = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        requestMaker.artistList = []
        await subject.receive(.allArtists)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(presenter.statePresented?.listType == .allArtists)
        #expect(presenter.statePresented?.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive composers: sends `getArtists` to request maker, filters, sets state, turns off spinner, sends effects")
    func receiveComposers() async {
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.composers)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(presenter.statePresented?.listType == .composers)
        #expect(presenter.statePresented?.artists == [
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ])
    }

    @Test("receive composers: gets list from cache if it exists, filters, sets state, turns off spinner, sends effects")
    func receiveComposersCached() async {
        caches.allArtists = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        requestMaker.artistList = []
        await subject.receive(.composers)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(presenter.statePresented?.listType == .composers)
        #expect(presenter.statePresented?.artists == [
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ])
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
        #expect(coordinator.methodsCalled.last == "showPlaylist(state:)")
        #expect(coordinator.playlistState == nil)
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

    @Test("receive viewIsAppearing: behaves like receiving .allArtists")
    func receiveViewIsAppearing() async {
        subject.state.animateSpinner = true
        subject.state.hasInitialData = false
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.viewIsAppearing)
        #expect(subject.state.hasInitialData)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled == ["getArtistsBySearch()"])
        #expect(presenter.statePresented?.listType == .allArtists)
        #expect(presenter.statePresented?.artists == [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
    }

    @Test("receive viewIsAppearing: does nothing if state hasInitialData")
    func receiveViewIsAppearingHasInitialData() async {
        subject.state.animateSpinner = true
        subject.state.hasInitialData = true
        requestMaker.artistList = [
            .init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil),
            .init(id: "2", name: "Composer", albumCount: nil, album: nil, roles: ["composer"], sortName: nil),
        ]
        await subject.receive(.viewIsAppearing)
        #expect(subject.state.hasInitialData == true)
        #expect(subject.state.animateSpinner == true)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(presenter.statePresented == nil)
    }

}
