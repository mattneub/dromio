@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct ArtistsDataSourceDelegateTests {
    var subject: ArtistsDataSourceDelegate!
    let tableView = MockTableView()

    init() async {
        subject = .init(tableView: tableView)
    }

    @Test("initializer: creates and sets the data source, sets the delegate")
    func initializer() async throws {
        await #while(subject.datasource == nil)
        #expect(subject.datasource != nil)
        #expect(tableView.dataSource === subject.datasource)
        #expect(tableView.delegate === subject)
        #expect(subject.tableView === tableView)
    }

    @Test("present: datasource reflects `albums`, if `allArtists` then sorted and sectionalized")
    func presentWithDataDatasourceItemsAll() async {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .allArtists)
        state.artists = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.listType == .allArtists)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["t", "y"])
        #expect(snapshot.itemIdentifiers(inSection: "t") == ["2"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
    }

    @Test("present: datasource reflects `artists`, if `composers` then sorted and sectionalized")
    func presentWithDataDatasourceItemsComposers() async {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .composers)
        state.artists = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.listType == .composers)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["t", "y"])
        #expect(snapshot.itemIdentifiers(inSection: "t") == ["2"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        await #while(subject.datasource == nil)
        makeWindow(view: tableView)
        var state = ArtistsState()
        state.artists = [.init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? ArtistsCellContentConfiguration)
        let expected = ArtistsCellContentConfiguration(artist: .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil))
        #expect(configuration == expected)
        #expect(tableView.methodsCalled.contains("beginUpdates()"))
        #expect(tableView.methodsCalled.contains("endUpdates()"))
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .background)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
    }

    @Test("present: does not call begin/endUpdates if we're not in a window")
    func presentWithDataCellNoWindow() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState()
        state.artists = [.init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? ArtistsCellContentConfiguration)
        let expected = ArtistsCellContentConfiguration(artist: .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil))
        #expect(configuration == expected)
        #expect(!tableView.methodsCalled.contains("beginUpdates()")) // *
        #expect(!tableView.methodsCalled.contains("endUpdates()")) // *
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .background)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
    }

    @Test("present: whether cells end up hidden depends on state's animateSpinner")
    func presentAnimateSpinner() async {
        await #while(subject.datasource == nil)
        var state = ArtistsState()
        state.artists = [.init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        do {
            state.animateSpinner = true
            await subject.present(state)
            await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
            await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
            let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
            #expect(cell!.isHidden)
        }
        do {
            state.animateSpinner = false
            await subject.present(state)
            await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
            await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
            let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
            #expect(!cell!.isHidden)
        }
    }

    @Test("sectionIndexTitles: with allArtists, returns uppercased section identifiers")
    func sectionIndexTitlesAll() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .allArtists)
        state.artists = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let result = try #require(subject.datasource.sectionIndexTitles(for: tableView))
        #expect(result == ["T", "Y"])
    }

    @Test("sectionIndexTitles: if searching, returns nil")
    func sectionIndexTitlesSearching() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .allArtists)
        state.artists = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        subject.datasource.searching = true
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.sectionIndexTitles(for: tableView) == nil)
    }

    @Test("sectionIndexTitles: with allArtists, but no actual albums, returns nil")
    func sectionIndexTitlesAllButNoData() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .allArtists)
        state.artists = []
        await subject.present(state)
        await #while(subject.datasource.sectionIdentifier(for: 0) == "Dummy") // it will become nil
        #expect(subject.datasource.sectionIndexTitles(for: tableView) == nil)
    }

    @Test("sectionIndexTitles: with composers, returns uppercased identifiers")
    func sectionIndexTitlesComposers() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .composers)
        state.artists = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let result = try #require(subject.datasource.sectionIndexTitles(for: tableView))
        #expect(result == ["T", "Y"])
    }

    @Test("sectionIndexTitles: with composers, but no actual albums, returns nil")
    func sectionIndexTitlesComposersButNoData() async throws {
        await #while(subject.datasource == nil)
        var state = ArtistsState(listType: .composers)
        state.artists = []
        await subject.present(state)
        await #while(subject.datasource.sectionIdentifier(for: 0) == "Dummy") // it will become nil
        #expect(subject.datasource.sectionIndexTitles(for: tableView) == nil)
    }

    @Test("updateSearchResults: if there is search bar text, filters data on it, updates datasource")
    func updateSearchResults() async {
        subject.originalData = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        let search = UISearchController()
        search.searchBar.text = "y"
        subject.updateSearchResults(for: search)
        #expect(subject.data == [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["y"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
    }

    @Test("updateSearchResults: if there is no search bar text, restores data, updates datasource")
    func updateSearchResultsNoText() async {
        subject.originalData = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        let search = UISearchController()
        search.searchBar.text = ""
        subject.updateSearchResults(for: search)
        #expect(subject.data == [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["t", "y"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
        #expect(snapshot.itemIdentifiers(inSection: "t") == ["2"])
    }

    @Test("updateSearchResults: if there is no search bar text and no originalData, just updates datasource")
    func updateSearchResultsNoTextNoOriginalData() async {
        subject.data = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        subject.originalData = []
        let search = UISearchController()
        search.searchBar.text = ""
        subject.updateSearchResults(for: search)
        #expect(subject.data == [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ])
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["t", "y"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
        #expect(snapshot.itemIdentifiers(inSection: "t") == ["2"])
    }

    @Test("willPresentSearchController: sets originalData, sets searching flag")
    func willPresent() {
        subject.originalData = []
        subject.data = [
            .init(id: "1", name: "Yoho", albumCount: nil, album: nil, roles: nil, sortName: nil),
            .init(id: "2", name: "Teehee", albumCount: nil, album: nil, roles: nil, sortName: nil),
        ]
        #expect(subject.datasource.searching == false)
        subject.willPresentSearchController(UISearchController())
        #expect(subject.datasource.searching == true)
        #expect(subject.originalData == subject.data)
    }

    @Test("willDismissSearchController: resets searching flag, calls table view reload section titles")
    func willDismiss() {
        subject.datasource.searching = true
        subject.willDismissSearchController(UISearchController())
        #expect(subject.datasource.searching == false)
        #expect(tableView.methodsCalled == ["reloadSectionIndexTitles()"])
    }

}
