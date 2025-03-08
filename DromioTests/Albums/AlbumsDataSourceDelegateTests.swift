@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumsDataSourceDelegateTests {
    var subject: AlbumsDataSourceDelegate!
    let tableView = UITableView()

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

    @Test("present: datasource reflects `albums`, if `allAlbums` then sorted and sectionalized")
    func presentWithDataDatasourceItemsAll() async {
        await #while(subject.datasource == nil)
        var state = AlbumsState(listType: .allAlbums)
        state.albums = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: nil, artist: "Artist", songCount: 30, song: nil),
        ]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.listType == .allAlbums)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["t", "y"])
        #expect(snapshot.itemIdentifiers(inSection: "t") == ["2"])
        #expect(snapshot.itemIdentifiers(inSection: "y") == ["1"])
    }

    @Test("present: datasource reflects `albums`, if `randomAlbums` then single section, order unchanged")
    func presentWithDataDatasourceItemsRandom() async {
        await #while(subject.datasource == nil)
        var state = AlbumsState(listType: .randomAlbums)
        state.albums = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: nil, artist: "Artist", songCount: 30, song: nil),
        ]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.listType == .randomAlbums)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["dummy"])
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["1", "2"])
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        await #while(subject.datasource == nil)
        makeWindow(view: tableView)
        var state = AlbumsState()
        state.albums = [.init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil)]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? AlbumsCellContentConfiguration)
        let expected = AlbumsCellContentConfiguration(album: .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil))
        #expect(configuration == expected)
    }

    @Test("sectionIndexTitles: with allAlbums, returns uppercased section identifiers")
    func sectionIndexTitlesAll() async throws {
        await #while(subject.datasource == nil)
        var state = AlbumsState(listType: .allAlbums)
        state.albums = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: nil, artist: "Artist", songCount: 30, song: nil),
        ]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let result = try #require(subject.datasource.sectionIndexTitles(for: tableView))
        #expect(result == ["T", "Y"])
    }

    @Test("sectionIndexTitles: with allAlbums, but no actual albums, returns nil")
    func sectionIndexTitlesAllButNoData() async throws {
        await #while(subject.datasource == nil)
        var state = AlbumsState(listType: .allAlbums)
        state.albums = []
        subject.present(state)
        await #while(subject.datasource.sectionIdentifier(for: 0) == "Dummy") // it will become nil
        #expect(subject.datasource.sectionIndexTitles(for: tableView) == nil)
    }

    @Test("sectionIndexTitles: with randomAlbums, returns nil")
    func sectionIndexTitlesRandom() async throws {
        await #while(subject.datasource == nil)
        var state = AlbumsState(listType: .randomAlbums)
        state.albums = [
            .init(id: "1", name: "Yoho", sortName: nil, artist: "Artist", songCount: 30, song: nil),
            .init(id: "2", name: "Teehee", sortName: nil, artist: "Artist", songCount: 30, song: nil),
        ]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        #expect(subject.datasource.sectionIndexTitles(for: tableView) == nil)
    }

}
