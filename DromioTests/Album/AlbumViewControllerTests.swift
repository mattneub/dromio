@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumViewControllerTests {
    let subject = AlbumViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumState, AlbumAction, Void>(tableView: UITableView())
    let processor = MockReceiver<AlbumAction>()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
    }

    @Test("Initialize: creates data source delegate, sets table view estimated row height")
    func initialize() throws {
        let subject = AlbumViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
        #expect(subject.tableView.estimatedRowHeight == 90)
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
        #expect(subject.view.backgroundColor == .background)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
    }

    @Test("present: presents to the data source")
    func present() async {
        let state = AlbumState(
            albumTitle: "Album",
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
                duration: nil,
                contributors: nil
            )]
        )
        subject.present(state)
        await #while(mockDataSourceDelegate.methodsCalled.last != "present(_:)")
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("receive animatePlaylist: tells the playlist bar button item to animate")
    func receiveAnimatePlaylist() throws {
        // I don't see how to test this: you can't ask a bar button item whether it has a symbol effect
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
