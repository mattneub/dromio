@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumsViewControllerTests {
    let subject = AlbumsViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumsState, AlbumsAction, Void>(tableView: UITableView())
    let processor = MockReceiver<AlbumsAction>()
    let searcher = MockSearcher()
    let tableView = MockTableView()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
        subject.searcher = searcher
    }

    @Test("Initialize: sets title to Albums, creates data source delegate, configures table view")
    func initialize() throws {
        let subject = AlbumsViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
        #expect(subject.tableView.estimatedRowHeight == 68)
        #expect(subject.tableView.sectionIndexColor == .systemRed)
    }

    @Test("Initialize: creates right bar button item")
    func initializeRight() throws {
        let item = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(item.title == nil)
        #expect(item.image == UIImage(systemName: "list.bullet"))
        #expect(item.target === subject)
        #expect(item.action == #selector(subject.showPlaylist))
    }

    @Test("Setting the processor sets the data source's processor")
    func setProcessor() {
        let processor2 = MockReceiver<AlbumsAction>()
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
    func viewDidLoad() async throws {
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
        subject.dataSourceDelegate = AlbumsDataSourceDelegate(tableView: tableView)
        var albums = [SubsonicAlbum]()
        for id in (1...100) {
            albums.append(.init(id: String(id), name: "name", sortName: nil, artist: "Artist", songCount: 10, song: nil))
        }
        makeWindow(viewController: subject)
        await subject.present(.init(albums: albums))
        await #while(tableView.numberOfRows(inSection: 0) < 100)
        tableView.scrollToRow(at: .init(row: 100, section: 0), at: .bottom, animated: false)
        // that was prep, this is the test
        await subject.receive(.scrollToZero)
        #expect(tableView.methodsCalled.last == "scrollToRow(at:at:animated:)")
        #expect(tableView.contentOffset.y == -20)
    }

    @Test("receive scrollToZero: does nothing if there are no cells")
    func scrollToZeroNoCells() async {
        // in order to test this we practically have to build that actual app!
        subject.tableView = tableView // who knew you could do that?
        subject.dataSourceDelegate = AlbumsDataSourceDelegate(tableView: tableView)
        let albums = [SubsonicAlbum]()
        makeWindow(viewController: subject)
        await subject.present(.init(albums: albums))
        // that was prep, this is the test
        await subject.receive(.scrollToZero)
        #expect(!tableView.methodsCalled.contains("scrollToRow(at:at:animated:)"))
    }

    @Test("receive setUpSearcher: calls searcher setUpSearcher")
    func setUpSearcher() async {
        await subject.receive(.setUpSearcher)
        #expect(searcher.methodsCalled == ["setUpSearcher(navigationItem:tableView:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.updater === subject.dataSourceDelegate)
    }

    @Test("receive tearDownSearcher: calls searcher tearDownSearcher")
    func tearDownSearcher() async {
        await subject.receive(.tearDownSearcher)
        #expect(searcher.methodsCalled == ["tearDownSearcher(navigationItem:tableView:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.tableView === subject.tableView)
    }

    @Test("present: presents to the data source")
    func present() async {
        let state = AlbumsState(albums: [.init(id: "1", name: "name", sortName: nil, artist: "Artist", songCount: 10, song: nil)])
        await subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("present: obeys the state's animateSpinner")
    func presentAnimateSpinner() async {
        let window = makeWindow(viewController: subject)
        let state = AlbumsState(animateSpinner: true)
        await subject.present(state)
        #expect(subject.activity.isAnimating == true)
        #expect(window.isUserInteractionEnabled == false)
        let state2 = AlbumsState(animateSpinner: false)
        await subject.present(state2)
        #expect(subject.activity.isAnimating == false)
        #expect(window.isUserInteractionEnabled == true)
    }

    @Test("present: sets the title and left bar button menu item according to the state, all albums")
    func presentAll() async throws {
        let state = AlbumsState(listType: .allAlbums)
        await subject.present(state)
        #expect(subject.title == "All Albums")
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 3)
        do {
            let action = menu.children[0]
            #expect(action.title == "Random Albums")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .randomAlbums)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[1]
            #expect(action.title == "Artists")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .artists)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[2]
            #expect(action.title == "Server")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .server)
        }
    }

    @Test("present: sets the title and left bar button menu item according to the state, random albums")
    func presentRandom() async throws {
        let state = AlbumsState(listType: .randomAlbums)
        await subject.present(state)
        #expect(subject.title == "Random Albums")
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 3)
        do {
            let action = menu.children[0]
            #expect(action.title == "All Albums")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .allAlbums)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[1]
            #expect(action.title == "Artists")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .artists)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[2]
            #expect(action.title == "Server")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .server)
        }
    }

    @Test("present: sets the title and no left bar button item, albums for artist")
    func presentAlbumsForArtist() async throws {
        let state = AlbumsState(listType: .albumsForArtist(id: "1", source: .artists))
        await subject.present(state)
        #expect(subject.title == nil)
        #expect(subject.navigationItem.leftBarButtonItem == nil)
    }

    @Test("showPlaylist: sends showPlaylist to processor")
    func showPlaylist() async {
        subject.showPlaylist()
        await #while(processor.thingsReceived.last != .showPlaylist)
        #expect(processor.thingsReceived.last == .showPlaylist)
    }
}
