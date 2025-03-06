@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumDataSourceDelegateTests {
    var subject: AlbumDataSourceDelegate!
    let tableView = UITableView()
    let processor = MockProcessor<AlbumAction, AlbumState>()

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
            duration: nil
        )]
        state.albumTitle = "My Album"
        subject.present(state)
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
            duration: nil
        )]
        state.totalCount = 10
        subject.present(state)
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
            duration: nil
        ), totalCount: 10)
        #expect(configuration == expected)
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
            duration: nil
        )]
        state.albumTitle = "My Album"
        subject.present(state)
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
            duration: nil
        )]
        state.albumTitle = nil
        subject.present(state)
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
            duration: nil
        )
        makeWindow(view: tableView)
        var state = AlbumState()
        state.songs = [song]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.contains(.tapped(song)))
    }
}
