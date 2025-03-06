@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PlaylistViewControllerTests {
    let subject = PlaylistViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<PlaylistState, PlaylistAction>(tableView: UITableView())
    let processor = MockReceiver<PlaylistAction>()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
    }

    @Test("Initialize: creates data source delegate, configures table view, sets title")
    func initialize() throws {
        let subject = PlaylistViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
        #expect(subject.tableView.estimatedRowHeight == 90)
        #expect(subject.title == "Playlist")
    }

    @Test("Setting the processor sets the data source's processor")
    func setProcessor() {
        let processor2 = MockReceiver<PlaylistAction>()
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

    @Test("viewDidLoad: creates right bar button item")
    func viewDidLoadRight() async throws {
        subject.loadViewIfNeeded()
        let rightBarButtonItem = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(rightBarButtonItem.title == "Clear")
        #expect(rightBarButtonItem.target === subject)
        #expect(rightBarButtonItem.action == #selector(subject.doClear))
    }

    @Test("present: presents to the data source")
    func present() {
        let state = PlaylistState(
            songs: [.init(
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
        )
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

    @Test("doClear: sends .clear to the processor")
    func doClear() async {
        subject.doClear()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .clear)
    }
}
