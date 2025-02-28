@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumViewControllerTests {
    let subject = AlbumViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumState, AlbumAction>(tableView: UITableView())
    let processor = MockReceiver<AlbumAction>()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
    }

    @Test("Initialize: creates data source delegate")
    func initialize() throws {
        let subject = AlbumViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
    }

    @Test("Initialize: creates right bar button item")
    func initializeRight() throws {
        let item = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(item.target === subject)
        #expect(item.action == #selector(subject.showPlaylist))
    }

    @Test("Setting the processor sets the data source's processor")
    func setProcessor() {
        let processor2 = MockReceiver<AlbumAction>()
        subject.processor = processor2
        #expect(mockDataSourceDelegate.processor === processor2)
    }

    @Test("viewDidLoad: sets the data source's processor, sets background color, sends .initialData action")
    func viewDidLoad() async {
        subject.loadViewIfNeeded()
        #expect(mockDataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .systemBackground)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
    }

    @Test("present: presents to the data source")
    func present() {
        let state = AlbumState(songs: [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2", suffix: nil, duration: nil)])
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("receive deselectAll: tells the table view to select nil")
    func receiveDeselectAll() {
        subject.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        #expect(subject.tableView.indexPathForSelectedRow != nil)
        subject.receive(.deselectAll)
        #expect(subject.tableView.indexPathForSelectedRow == nil)
    }

    @Test("showPlaylist: sends showPlaylist to processor")
    func showPlaylist() async {
        subject.showPlaylist()
        await #while(processor.thingsReceived.last != .showPlaylist)
        #expect(processor.thingsReceived.last == .showPlaylist)
    }
}
