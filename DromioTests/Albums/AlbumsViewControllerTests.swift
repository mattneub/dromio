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

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
        subject.searcher = searcher
    }

    @Test("Initialize: sets title to Albums, creates data source delegate, configures table view")
    func initialize() throws {
        let subject = AlbumsViewController(nibName: nil, bundle: nil)
        #expect(subject.title == "All Albums")
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

    @Test("viewDidLoad: sets the data source's processor, sets background color, sets spinner, sends .initialData action")
    func viewDidLoad() async throws {
        subject.loadViewIfNeeded()
        #expect(mockDataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .background)
        let tableBackground = try #require(subject.tableView.backgroundView)
        #expect(subject.activity.isDescendant(of: tableBackground))
        #expect(subject.activity.isAnimating)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
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
        let state = AlbumsState(albums: [.init(id: "1", name: "name", sortName: nil, artist: "Artist", songCount: 10, song: nil)])
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("present: stops spinner, calls searcher setUpSearcher")
    func presentSearcher() async {
        let state = AlbumsState(albums: [.init(id: "1", name: "name", sortName: nil, artist: "Artist", songCount: 10, song: nil)])
        subject.present(state)
        #expect(!subject.activity.isAnimating)
        await #while(searcher.methodsCalled.isEmpty)
        #expect(searcher.methodsCalled == ["setUpSearcher(navigationItem:updater:)"])
        #expect(searcher.navigationItem === subject.navigationItem)
        #expect(searcher.updater === subject.dataSourceDelegate)
    }

    @Test("present: sets the title and left bar button menu item according to the state, all albums")
    func presentAll() async throws {
        let state = AlbumsState(listType: .allAlbums)
        subject.present(state)
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
        subject.present(state)
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
        subject.present(state)
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
