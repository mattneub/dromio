@testable import Dromio
import Testing

@MainActor
struct AlbumsProcessorTests {
    let subject = AlbumsProcessor()
    let presenter = MockReceiverPresenter<AlbumsEffect, AlbumsState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.requestMaker = requestMaker
        services.cache.clear()
        subject.cycler = MockCycler(processor: subject)
    }

    @Test("receive allAlbums: starts by presenting spinner animation")
    func receiveAllAlbumsStart() async {
        subject.state.animateSpinner = false
        #expect(presenter.statePresented == nil)
        await subject.receive(.allAlbums)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
    }

    @Test("receive allAlbums: sends `tearDown` effect, sends `getAlbumList` to request maker, sets state, turns off spinner, sends searcher/scroll effects")
    func receiveAllAlbums() async {
        subject.state.animateSpinner = true
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        #expect(presenter.statePresented == nil)
        await subject.receive(.allAlbums)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.tearDownSearcher, .setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(presenter.statePresented?.listType == .allAlbums)
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive allAlbums: sorts the list, injecting sortName, and sets the cache to the sorted list")
    func receiveAllAlbumsSorts() async {
        requestMaker.albumList = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: nil, artist: "Artist", songCount: 30, song: nil),
        ]
        await subject.receive(.allAlbums)
        #expect(presenter.statePresented?.albums == [
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
            .init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)
        ])
        #expect(services.cache.allAlbums == [
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
            .init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)
        ])
    }

    @Test("receive allAlbums: gets list from cache if it exists, sends teardown, sets state, turns off spinner, sends searcher/scroll effects")
    func receiveAllAlbumsCached() async {
        subject.state.animateSpinner = true
        services.cache.allAlbums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        requestMaker.albumList = []
        #expect(presenter.statePresented == nil)
        await subject.receive(.allAlbums)
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.tearDownSearcher, .setUpSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(presenter.statePresented?.listType == .allAlbums)
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive artists: tells coordinator to showArtists")
    func showArtists() async {
        await subject.receive(.artists)
        #expect(coordinator.methodsCalled.last == "showArtists()")
    }

    @Test("receive initialData: turns on hasInitialData, starts by presenting state with spinner on, ultimately turns it off")
    func receiveInitialDataSpinner() async {
        subject.state.animateSpinner = false
        subject.state.hasInitialData = false
        subject.state.listType = .albumsForArtist(id: "1", source: .artists)
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(subject.state.hasInitialData == true)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
        #expect(presenter.statesPresented.last?.animateSpinner == false)
    }

    @Test("receive initialData: turns on hasInitialData, starts by presenting state with spinner on, ultimately turns it off")
    func receiveInitialDataSpinner2() async {
        subject.state.animateSpinner = false
        subject.state.hasInitialData = false
        subject.state.listType = .allAlbums // *
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(subject.state.hasInitialData == true)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
        await subject.receive(.allAlbums) // because that's what the cycler does!
        #expect(presenter.statesPresented.last?.animateSpinner == false)
    }

    @Test("receive initialData: if `hasInitialData` is true, just stops")
    func receiveInitialDataHasInitialData() async {
        subject.state.hasInitialData = true
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(subject.state.hasInitialData == true)
        #expect(presenter.statesPresented == [])
    }

    @Test("receive initialData: if listType is .albumsForArtist and source .artists, sends getAlbumsFor with id to request maker, sets state")
    func receiveInitialDataForArtist() async {
        subject.state.listType = .albumsForArtist(id: "1", source: .artists)
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumsFor(artistId:)"])
        #expect(requestMaker.artistId == "1")
        #expect(presenter.statePresented?.listType == .albumsForArtist(id: "1", source: .artists))
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived.isEmpty) // not searchable
    }

    @Test("receive initialData: for albumsForArtist, source artist, sorts the list from the requestMaker")
    func receiveInitialDataForArtistSorts() async {
        subject.state.listType = .albumsForArtist(id: "1", source: .artists)
        requestMaker.albumList = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
        ]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.albums == [
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
            .init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)
        ])
    }

    @Test("receive initialData: if listType is .albumsForArtist and source .composers, sends getSongsBySearch with name to request maker, sets state")
    func receiveInitialDataForComposer() async {
        subject.state.listType = .albumsForArtist(id: "1", source: .composers(name: "Me"))
        requestMaker.songList = [.init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Moi", albumCount: nil, album: nil, roles: nil))]
        )]
        services.cache.allAlbums = [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)]
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getSongsBySearch(query:)"])
        #expect(requestMaker.query == "Me")
        #expect(presenter.statePresented?.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived.isEmpty) // not searchable
    }

    @Test("receive initialData:, listType albumsForArtist for source composers, keeps sort order from cache")
    func receiveInitialDataForComposerSorted() async {
        subject.state.listType = .albumsForArtist(id: "1", source: .composers(name: "Me"))
        requestMaker.songList = [.init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Moi", albumCount: nil, album: nil, roles: nil))]
        ), .init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Moi", albumCount: nil, album: nil, roles: nil))]
        )]
        services.cache.allAlbums = [
            .init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil),
            .init(id: "3", name: "ZZ", sortName: "zz", artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
        ]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.albums == [
            .init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: "teehee", artist: "Artist", songCount: 30, song: nil),
        ])
    }

    @Test("receive initialData:, listType .albumsForArtist for source .composers, red/green testing the filter")
    func receiveInitialDataComposersRedGreen() async {
        // these are our albums
        services.cache.allAlbums = [.init(
            id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil
        ), .init(
            id: "2", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil
        )]
        // this is the song search info
        subject.state.listType = .albumsForArtist(id: "1", source: .composers(name: "Me"))
        requestMaker.songList = [.init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil))]
        ), .init(
            id: "2",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "2",
            suffix: nil,
            duration: nil,
            // this artist is a composer with the right name but the wrong id, so his album doesn't match
            contributors: [.init(role: "composer", artist: .init(id: "2", name: "Me", albumCount: nil, album: nil, roles: nil))]
        )]
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        //
        presenter.statePresented = nil
        subject.state.hasInitialData = false
        requestMaker.songList = [.init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil))]
        ), .init(
            id: "2",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "2",
            suffix: nil,
            duration: nil,
            // this artist has the right id but on this song he is not a composer, so his album doesn't match
            contributors: [.init(role: "artist", artist: .init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil))]
        )]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        //
        presenter.statePresented = nil
        subject.state.hasInitialData = false
        requestMaker.songList = [.init(
            id: "1",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil))]
        ), .init(
            id: "2",
            title: "Tra-la",
            album: nil,
            artist: nil,
            displayComposer: nil,
            track: nil,
            year: nil,
            albumId: "1",
            suffix: nil,
            duration: nil,
            // this artist is exactly the same as the first, and the song album is the same, but it counts just once
            contributors: [.init(role: "composer", artist: .init(id: "1", name: "Me", albumCount: nil, album: nil, roles: nil))]
        )]
        await subject.receive(.initialData)
        #expect(presenter.statePresented?.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive initialData: if listType is .allAlbums sends .allAlbums")
    func receiveInitialDataAllAlbums() async throws {
        subject.state.listType = .allAlbums
        subject.state.animateSpinner = false
        subject.state.hasInitialData = false
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
        #expect(presenter.statesPresented.first?.hasInitialData == true)
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.allAlbums])
    }

    @Test("receive randomAlbums: starts by sending `tearDown` and starting the spinner")
    func receiveRandomAlbumsStart() async {
        subject.state.animateSpinner = false
        await subject.receive(.randomAlbums)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
        #expect(presenter.thingsReceived.first == .tearDownSearcher)
    }

    @Test("receive randomAlbums: sends `scrollToZero` effect, sends `getAlbumList` to request maker, sets state, turns off spinner")
    func receiveRandomAlbums() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        #expect(presenter.statePresented == nil)
        await subject.receive(.randomAlbums)
        #expect(presenter.thingsReceived == [.tearDownSearcher, .scrollToZero])
        #expect(requestMaker.methodsCalled == ["getAlbumsRandom()"])
        #expect(presenter.statePresented?.listType == .randomAlbums)
        #expect(presenter.statePresented?.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
        #expect(presenter.statePresented?.animateSpinner == false)
    }

    @Test("receive server: sends dismissToPing to coordinator")
    func receiveServer() async {
        await subject.receive(.server)
        #expect(coordinator.methodsCalled.last == "dismissToPing()")
    }

    @Test("showAlbum: sends no effect, no presentation, sends `showAlbum` to coordinator, with info from specified album")
    func showAlbum() async {
        subject.state.albums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.showAlbum(albumId: "1"))
        #expect(presenter.statePresented == nil)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(coordinator.methodsCalled == ["showAlbum(albumId:title:)"])
        #expect(coordinator.albumId == "1")
        #expect(coordinator.title == "Yoho")
    }

    @Test("receive showPlaylist: sends no effect, no presentation, tells coordinator to showPlaylist")
    func showPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(presenter.statePresented == nil)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(coordinator.methodsCalled.last == "showPlaylist(state:)")
        #expect(coordinator.playlistState == nil)
    }
}
