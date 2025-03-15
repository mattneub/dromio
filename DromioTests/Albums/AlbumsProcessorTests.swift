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
        caches.albumsList = nil
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albums.append(.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
        #expect(presenter.statePresented?.albums.first == .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
    }

    @Test("receive initialData: if listType is .albumsForArtist and source .artists, sends getAlbumsFor with id to request maker, sets state")
    func receiveInitialDataForArtist() async {
        subject.state.listType = .albumsForArtist(id: "1", source: .artists)
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumsFor(artistId:)"])
        #expect(requestMaker.artistId == "1")
        #expect(subject.state.listType == .albumsForArtist(id: "1", source: .artists))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
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
        caches.albumsList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getSongsBySearch(query:)"])
        #expect(requestMaker.query == "Me")
        #expect(subject.state.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive initialData:, listType .albumsForArtist for source .composers, red/green testing the filter")
    func receiveInitialDataComposersRedGreen() async {
        // these are our albums
        caches.albumsList = [.init(
            id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil
        ), .init(
            id: "2", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil
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
        await subject.receive(.initialData)
        #expect(subject.state.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        //
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
        #expect(subject.state.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
        //
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
        #expect(subject.state.listType == .albumsForArtist(id: "1", source: .composers(name: "Me")))
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: "yoho", artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive initialData: if listType is .allAlbums behaves exactly as receiving .allAlbums")
    func receiveInitialDataAllAlbums() async {
        subject.state.listType = .allAlbums
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.initialData)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(subject.state.listType == .allAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive allAlbums: sends `tearDown` effect, sends `getAlbumList` to request maker, sets state")
    func receiveAllAlbums() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.allAlbums)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
        #expect(subject.state.listType == .allAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive allAlbums: gets list from cache if it exists, sends teardown, sends getAlbumList, sets state")
    func receiveAllAlbumsCached() async {
        caches.albumsList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        requestMaker.albumList = []
        await subject.receive(.allAlbums)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(subject.state.listType == .allAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("receive randomAlbums: sends `tearDown` effect, sends `getAlbumList` to request maker, sets state")
    func receiveRandomAlbums() async {
        requestMaker.albumList = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.randomAlbums)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(requestMaker.methodsCalled == ["getAlbumsRandom()"])
        #expect(subject.state.listType == .randomAlbums)
        #expect(subject.state.albums == [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)])
    }

    @Test("showAlbum: sends no effect, sends `showAlbum` to coordinator, with info from specified album")
    func showAlbum() async {
        subject.state.albums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        await subject.receive(.showAlbum(albumId: "1"))
        #expect(presenter.thingsReceived.isEmpty)
        #expect(coordinator.methodsCalled == ["showAlbum(albumId:title:)"])
        #expect(coordinator.albumId == "1")
        #expect(coordinator.title == "Yoho")
    }

    @Test("receive artists: sends `tearDown` effect, tells coordinator to showArtists")
    func showArtists() async {
        await subject.receive(.artists)
        #expect(presenter.thingsReceived == [.tearDownSearcher])
        #expect(coordinator.methodsCalled.last == "showArtists()")
    }

    @Test("receive showPlaylist: sends no effect, tells coordinator to showPlaylist")
    func showPlaylist() async {
        await subject.receive(.showPlaylist)
        #expect(presenter.thingsReceived.isEmpty)
        #expect(coordinator.methodsCalled.last == "showPlaylist()")
    }

    @Test("receive viewDidAppear: sends `setUpSearcher` effect")
    func receiveViewDidAppear() async {
        await subject.receive(.viewDidAppear)
        #expect(presenter.thingsReceived == [.setUpSearcher])
    }
}
