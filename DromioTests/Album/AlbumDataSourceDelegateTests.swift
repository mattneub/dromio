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

    @Test("present: datasource reflects `songs`")
    func presentWithDataDatasourceItems() async {
        var state = AlbumState()
        state.songs = [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 1)
        #expect(snapshot.itemIdentifiers.first == "1")
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        makeWindow(view: tableView)
        var state = AlbumState()
        state.songs = [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? UIListContentConfiguration)
        #expect(configuration.text == "Title")
    }

    @Test("didSelect: sends tapped to processor")
    func didSelect() async {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")
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
