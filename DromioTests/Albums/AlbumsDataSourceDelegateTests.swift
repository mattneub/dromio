@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumsDataSourceDelegateTests {
    var subject: AlbumsDataSourceDelegate!
    let tableView = UITableView()

    init() {
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

    @Test("present: datasource reflects `albums`")
    func presentWithDataDatasourceItems() async {
        var state = AlbumsState()
        state.albums = [.init(id: "1", name: "Yoho", artist: "Artist", songCount: 30, song: nil)]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 1)
        #expect(snapshot.itemIdentifiers.first == "1")
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        makeWindow(view: tableView)
        var state = AlbumsState()
        state.albums = [.init(id: "1", name: "Yoho", artist: "Artist", songCount: 30, song: nil)]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? AlbumsCellContentConfiguration)
        #expect(configuration.title == "Yoho")
        #expect(configuration.artist == "Artist")
        #expect(configuration.tracks == 30)
    }

}
