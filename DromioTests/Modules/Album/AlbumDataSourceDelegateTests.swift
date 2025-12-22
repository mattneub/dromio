@testable import Dromio
import Testing
import UIKit
import WaitWhile

struct AlbumDataSourceDelegateTests {
    var subject: AlbumDataSourceDelegate!
    let tableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    let processor = MockProcessor<AlbumAction, AlbumState, AlbumEffect>()

    init() {
        subject = .init(tableView: tableView)
        subject.processor = processor
    }

    @Test("initializer: creates and sets the data source, sets the delegate")
    func initializer() async throws {
        await #while(subject.datasource == nil)
        #expect(subject.datasource != nil)
        #expect(tableView.dataSource === subject.datasource)
        #expect(tableView.delegate === subject)
        #expect(subject.tableView === tableView)
    }

    @Test("present: datasource reflects `songs` and `albumTitle`")
    func presentWithDataDatasourceItems() async {
        var state = AlbumState()
        state.songs = [.init(
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
        state.albumTitle = "My Album"
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 1)
        #expect(snapshot.itemIdentifiers.first == "1")
        #expect(snapshot.sectionIdentifiers.first == "My Album")
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        makeWindow(view: tableView)
        var state = AlbumState()
        state.songs = [.init(
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
        ), .init(
            id: "2",
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
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? AlbumCellContentConfiguration)
        let expected = AlbumCellContentConfiguration(song: SubsonicSong(
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
        ), totalCount: 2)
        #expect(configuration == expected)
        #expect(tableView.methodsCalled.contains("beginUpdates()"))
        #expect(tableView.methodsCalled.contains("endUpdates()"))
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .background)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
    }

    @Test("present: does not call begin/endUpdates if we're not in a window")
    func presentWithDataCellNotInWindow() async throws {
        var state = AlbumState()
        state.songs = [.init(
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
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? AlbumCellContentConfiguration)
        let expected = AlbumCellContentConfiguration(song: SubsonicSong(
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
        ), totalCount: 1)
        #expect(configuration == expected)
        #expect(!tableView.methodsCalled.contains("beginUpdates()")) // *
        #expect(!tableView.methodsCalled.contains("endUpdates()")) // *
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .background)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
    }


    @Test("present: whether cells end up hidden depends on state's animateSpinner")
    func presentAnimateSpinner() async {
        makeWindow(view: tableView)
        await #while(subject.datasource == nil)
        var state = AlbumState()
        state.songs = [.init(
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
        ), .init(
            id: "2",
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
        do {
            state.animateSpinner = true
            await subject.present(state)
            await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
            await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
            let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
            #expect(cell?.isHidden == true)
        }
        do {
            state.animateSpinner = false
            await subject.present(state)
            await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
            await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
            let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
            #expect(cell?.isHidden == false)
        }
    }

    @Test("viewForHeaderInSection: correctly populates header view")
    func viewForHeader() async throws {
        var state = AlbumState()
        state.songs = [.init(
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
        state.albumTitle = "My Album"
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let headerView = try #require(subject.tableView(tableView, viewForHeaderInSection: 0) as? UITableViewHeaderFooterView)
        let configuration = try #require(headerView.contentConfiguration as? UIListContentConfiguration)
        #expect(configuration.text == "My Album")
        #expect(configuration.textProperties.font == UIFont(name: "Verdana-Bold", size: 17))
        #expect(configuration.textProperties.alignment == .center)
    }

    @Test("viewForHeaderInSection: is nil if album title is nil")
    func viewForHeaderNil() async throws {
        var state = AlbumState()
        state.songs = [.init(
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
        state.albumTitle = nil
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.tableView(tableView, viewForHeaderInSection: 0) == nil)
    }

    @Test("didSelect: sends tapped to processor")
    func didSelect() async {
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
        makeWindow(view: tableView)
        var state = AlbumState()
        state.songs = [song]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.contains(.tapped(song)))
    }

    @Test("updateSearchResults: if there is search bar text, filters data on it, updates datasource")
    func updateSearchResults() async {
        subject.originalData = [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
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
        subject.albumTitle = "My Album"
        let search = UISearchController()
        search.searchBar.text = "y"
        subject.updateSearchResults(for: search)
        #expect(subject.data == [
            .init(
                id: "1",
                title: "Yoho",
                album: "Album",
                artist: "Artist",
                displayComposer: "Me",
                track: 1,
                year: 1970,
                albumId: "2",
                suffix: nil,
                duration: nil,
                contributors: nil
            ),
        ])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["My Album"])
        #expect(snapshot.itemIdentifiers(inSection: "My Album") == ["1"])
    }

    @Test("updateSearchResults: if there is no search bar text, restores data, updates datasource")
    func updateSearchResultsNoText() async {
        subject.originalData = [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
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
        subject.albumTitle = "My Album"
        let search = UISearchController()
        search.searchBar.text = ""
        subject.updateSearchResults(for: search)
        #expect(subject.data == [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["My Album"])
        #expect(snapshot.itemIdentifiers(inSection: "My Album") == ["1", "2"])
    }

    @Test("updateSearchResults: if there is no search bar text and no originalData, just updates datasource")
    func updateSearchResultsNoTextNoOriginalData() async {
        subject.data = [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
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
        subject.originalData = []
        subject.albumTitle = "My Album"
        let search = UISearchController()
        search.searchBar.text = ""
        subject.updateSearchResults(for: search)
        #expect(subject.data == [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["My Album"])
        #expect(snapshot.itemIdentifiers(inSection: "My Album") == ["1", "2"])
    }

    @Test("willPresentSearchController: sets originalData")
    func willPresent() {
        subject.originalData = []
        subject.data = [.init(
            id: "1",
            title: "Yoho",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        ), .init(
            id: "2",
            title: "Teehee",
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
        subject.willPresentSearchController(UISearchController())
        #expect(subject.originalData == subject.data)
    }
}
