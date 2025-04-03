@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumViewControllerTests {
    let subject = AlbumViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumState, AlbumAction, Void>(tableView: UITableView())
    let processor = MockReceiver<AlbumAction>()
    let tableView = MockTableView()
    let searcher = MockSearcher()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
        subject.searcher = searcher
    }

    @Test("Initialize: creates data source delegate, sets table view estimated row height")
    func initialize() throws {
        let subject = AlbumViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
        #expect(subject.tableView.estimatedRowHeight == 90)
        #expect(subject.tableView.sectionHeaderTopPadding == 0)
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

    @Test("Activity spinner is correctly constructed")
    func activitySpinner() throws {
        let spinner = subject.activity
        #expect(spinner.style == .large)
        #expect(spinner.color == .label)
        #expect(spinner.backgroundColor!.resolvedColor(with: .init(userInterfaceStyle: .dark)) == UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light)))
        #expect(spinner.backgroundColor!.resolvedColor(with: .init(userInterfaceStyle: .light)) == UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .dark)))
        #expect(spinner.layer.cornerRadius == 20)
    }

    @Test("viewDidLoad: sets the data source's processor, sets background color, sets spinner")
    func viewDidLoad() async {
        subject.loadViewIfNeeded()
        #expect(mockDataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .background)
        #expect(subject.activity.isDescendant(of: subject.view))
    }

    @Test("viewIsAppearing: sends .initialData action")
    func viewIsAppearing() async {
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived.last != .initialData)
        #expect(processor.thingsReceived.last == .initialData)
    }

    @Test("receive scrollToZero: scrolls to zero")
    func scrollToZero() async {
        // in order to test this we practically have to build that actual app!
        subject.tableView = tableView // who knew you could do that?
        subject.dataSourceDelegate = AlbumDataSourceDelegate(tableView: tableView)
        var songs = [SubsonicSong]()
        for id in (1...100) {
            songs.append(.init(id: String(id), title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil))
        }
        makeWindow(viewController: subject)
        await subject.present(.init(songs: songs))
        await #while(tableView.numberOfRows(inSection: 0) < 100)
        tableView.scrollToRow(at: .init(row: 100, section: 0), at: .bottom, animated: false)
        // that was prep, this is the test
        await subject.receive(.scrollToZero)
        #expect(tableView.contentOffset.y == -20)
    }

    @Test("receive setUpSearcher: calls searcher setUpSearcher")
    func setUpSearcher() async {
        await subject.receive(.setUpSearcher)
        #expect(searcher.methodsCalled == ["setUpSearcher(navigationItem:tableView:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.updater === subject.dataSourceDelegate)
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
        await subject.present(state)
        await #while(mockDataSourceDelegate.methodsCalled.last != "present(_:)")
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("present: obeys the state's animateSpinner")
    func presentAnimateSpinner() async {
        let window = makeWindow(viewController: subject)
        let state = AlbumState(animateSpinner: true)
        await subject.present(state)
        #expect(subject.activity.isAnimating == true)
        #expect(window.isUserInteractionEnabled == false)
        let state2 = AlbumState(animateSpinner: false)
        await subject.present(state2)
        #expect(subject.activity.isAnimating == false)
        #expect(window.isUserInteractionEnabled == true)
    }

    @Test("receive animatePlaylist: tells the playlist bar button item to animate")
    func receiveAnimatePlaylist() throws {
        // I don't see how to test this: you can't ask a bar button item whether it has a symbol effect
    }

    @Test("receive deselectAll: tells the table view to select nil")
    func receiveDeselectAll() async {
        subject.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        #expect(subject.tableView.indexPathForSelectedRow != nil)
        await subject.receive(.deselectAll)
        #expect(subject.tableView.indexPathForSelectedRow == nil)
    }

    @Test("showPlaylist: sends showPlaylist to processor")
    func showPlaylist() async {
        subject.showPlaylist()
        await #while(processor.thingsReceived.last != .showPlaylist)
        #expect(processor.thingsReceived.last == .showPlaylist)
    }
}
