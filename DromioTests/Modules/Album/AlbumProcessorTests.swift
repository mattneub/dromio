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

    @Test("receive initialData: turns on initialdata, starts by presenting spinner animation")
    func receiveAInitialDataStart() async {
        subject.state.hasInitialData = false
        subject.state.animateSpinner = false
        #expect(presenter.statePresented == nil)
        await subject.receive(.initialData)
        #expect(subject.state.hasInitialData == true)
        #expect(presenter.statesPresented.first?.animateSpinner == true)
    }

    @Test("receive initialData: sends `getSongsFor` to request maker, sets state songs, turns off spinner, sends effects")
    func receiveInitialData() async {
        requestMaker.songList = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        subject.state.albumId = "2"
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getSongsFor(albumId:)"])
        #expect(requestMaker.albumId == "2")
        #expect(
            presenter.statePresented?.songs == [.init(
                id: "1",
                title: "Title",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil
            )]
        )
        #expect(presenter.statePresented?.animateSpinner == false)
        #expect(presenter.thingsReceived == [.setUpSearcher, .scrollToZero])
    }

    @Test("receive initialData: does nothing state hasInitialData")
    func receiveInitialDataHasInitialData() async {
        subject.state.hasInitialData = true
        requestMaker.songList = [.init(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )]
        subject.state.albumId = "2"
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(presenter.statePresented == nil)
        #expect(presenter.thingsReceived.isEmpty)
    }

    @Test("receive tapped: appends to current playlist, calls haptic success, sends animatePlaylist and deselectAll effect")
    func receiveTapped() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        await subject.receive(.tapped(song))
        #expect(playlist.methodsCalled == ["append(_:)"])
        #expect(haptic.methodsCalled == ["success()"])
        await #while(presenter.thingsReceived.isEmpty)
        #expect(presenter.thingsReceived == [.animatePlaylist, .deselectAll])
    }

    @Test("receive tapped: receiving error from append calls haptic failure, sends no animatePlaylist, sends deselectAll effect")
    func receiveTappedFailure() async {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
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
        #expect(coordinator.methodsCalled.last == "showPlaylist(state:)")
        #expect(coordinator.playlistState == nil)
    }
}
