@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct ArtistsViewControllerTests {
    let subject = ArtistsViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<ArtistsState, ArtistsAction, Void>(tableView: UITableView())
    let processor = MockReceiver<ArtistsAction>()
    let searcher = MockSearcher()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
        subject.searcher = searcher
    }

    @Test("Initialize: sets title to Artists, creates data source delegate, configures table view")
    func initialize() throws {
        let subject = ArtistsViewController(nibName: nil, bundle: nil)
        #expect(subject.title == "All Artists")
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
        #expect(subject.tableView.estimatedRowHeight == 40)
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

    @Test("Initialize: creates left bar button item")
    func initializeLeft() throws {
        let item = try #require(subject.navigationItem.leftBarButtonItem)
        #expect(item.title == nil)
        #expect(item.image == UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"))
        #expect(item.menu != nil)
    }

    @Test("Setting the processor sets the data source's processor")
    func setProcessor() {
        let processor2 = MockReceiver<ArtistsAction>()
        subject.processor = processor2
        #expect(mockDataSourceDelegate.processor === processor2)
    }

    @Test("viewDidLoad: sets the data source's processor, sets background color, sends .allArtists action")
    func viewDidLoad() async {
        subject.loadViewIfNeeded()
        #expect(mockDataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .systemBackground)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .allArtists)
    }

    @Test("viewDidAppear: sends .viewDidAppear action")
    func viewDidAppear() async {
        subject.viewDidAppear(false)
        await #while(processor.thingsReceived.last != .viewDidAppear)
        #expect(processor.thingsReceived.last == .viewDidAppear)
    }

    @Test("receive setUpSearcher: calls searcher setUpSearcher")
    func setUpSearcher() async {
        await subject.receive(.setUpSearcher)
        #expect(searcher.methodsCalled == ["setUpSearcher(navigationItem:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.updater === subject.dataSourceDelegate)
    }

    @Test("receive tearDownSearcher: calls searcher tearDownSearcher")
    func tearDownSearcher() async {
        await subject.receive(.tearDownSearcher)
        #expect(searcher.methodsCalled == ["tearDownSearcher(navigationItem:tableView:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.tableView === subject.tableView)
    }

    @Test("present: presents to the data source")
    func present() {
        let state = ArtistsState(artists: [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("present: calls searcher setUpSearcher")
    func presentSearcher() async {
        let state = ArtistsState(artists: [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
        subject.present(state)
        await #while(searcher.methodsCalled.isEmpty)
        #expect(searcher.methodsCalled == ["setUpSearcher(navigationItem:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.updater === subject.dataSourceDelegate)
    }

    @Test("present: sets the title and left bar button menu item according to the state")
    func presentAll() async throws {
        let state = ArtistsState(listType: .allArtists)
        subject.present(state)
        #expect(subject.title == "All Artists")
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 2)
        do {
            let action = menu.children[0]
            #expect(action.title == "Composers")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .composers)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[1]
            #expect(action.title == "Albums")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .albums)
        }
    }

    @Test("present: sets the title and left bar button menu item according to the state")
    func presentRandom() async throws {
        let state = ArtistsState(listType: .composers)
        subject.present(state)
        #expect(subject.title == "Composers")
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 2)
        do {
            let action = menu.children[0]
            #expect(action.title == "All Artists")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .allArtists)
        }
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[1]
            #expect(action.title == "Albums")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .albums)
        }
    }

    @Test("showPlaylist: sends showPlaylist to processor")
    func showPlaylist() async {
        subject.showPlaylist()
        await #while(processor.thingsReceived.last != .showPlaylist)
        #expect(processor.thingsReceived.last == .showPlaylist)
    }
}
