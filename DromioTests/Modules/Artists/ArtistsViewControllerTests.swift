@testable import Dromio
import Testing
import UIKit
import WaitWhile

struct ArtistsViewControllerTests {
    let subject = ArtistsViewController()
    let mockDataSourceDelegate = MockDataSourceDelegate<ArtistsState, ArtistsAction, Void>(tableView: UITableView())
    let processor = MockReceiver<ArtistsAction>()
    let configurator = MockSearchConfigurator()
    let tableView = MockTableView()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
        subject.searchConfigurator = configurator
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

    @Test("real viewDidLoad: configures the data source delegate")
    func viewDidLoadReal() {
        let subject = AlbumViewController()
        subject.loadViewIfNeeded()
        #expect(subject.dataSourceDelegate.tableView == subject.tableView)
    }

    @Test("viewDidLoad: sets background color, sets spinner, bar button items, table view, search")
    func viewDidLoad() async throws {
        subject.loadViewIfNeeded()
        #expect(subject.dataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .background)
        #expect(subject.activity.isDescendant(of: subject.view))
        #expect(subject.tableView.estimatedRowHeight == 40)
        #expect(subject.tableView.sectionIndexColor == .systemRed)
        do {
            let item = try #require(subject.navigationItem.rightBarButtonItem)
            #expect(item.title == nil)
            #expect(item.image == UIImage(systemName: "list.bullet"))
            #expect(item.target === subject)
            #expect(item.action == #selector(subject.showPlaylist))
        }
        do {
            let item = try #require(subject.navigationItem.leftBarButtonItem)
            #expect(item.title == nil)
            #expect(item.image == UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"))
            #expect(item.menu != nil)
        }
        #expect(configurator.methodsCalled == ["configure(viewController:updater:)"])
        #expect(configurator.viewController === subject)
        #expect(configurator.updater === mockDataSourceDelegate)
    }

    @Test("viewIsAppearing: sends .viewIsAppearing action")
    func viewIsAppearing() async {
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived.last != .viewIsAppearing)
        #expect(processor.thingsReceived.last == .viewIsAppearing)
    }

    @Test("receive scrollToZero: scrolls to zero")
    func scrollToZero() async {
        // in order to test this we practically have to build that actual app!
        subject.tableView = tableView // who knew you could do that?
        subject.dataSourceDelegate = ArtistsDataSourceDelegate(tableView: tableView)
        var artists = [SubsonicArtist]()
        for id in (1...100) {
            artists.append(.init(id: String(id), name: "name", albumCount: nil, album: nil, roles: nil))
        }
        makeWindow(viewController: subject)
        await subject.present(.init(artists: artists))
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
        subject.dataSourceDelegate = ArtistsDataSourceDelegate(tableView: tableView)
        let artists = [SubsonicArtist]()
        makeWindow(viewController: subject)
        await subject.present(.init(artists: artists))
        // that was prep, this is the test
        await subject.receive(.scrollToZero)
        #expect(!tableView.methodsCalled.contains("scrollToRow(at:at:animated:)"))
    }

    @Test("present: presents to the data source")
    func present() async {
        let state = ArtistsState(artists: [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: ["artist"], sortName: nil)])
        await subject.present(state)
        await #while(mockDataSourceDelegate.methodsCalled.last != "present(_:)")
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    @Test("present: obeys the state's animateSpinner")
    func presentAnimateSpinner() async {
        let window = makeWindow(viewController: subject)
        let state = ArtistsState(animateSpinner: true)
        await subject.present(state)
        #expect(subject.activity.isAnimating == true)
        #expect(window.isUserInteractionEnabled == false)
        let state2 = ArtistsState(animateSpinner: false)
        await subject.present(state2)
        #expect(subject.activity.isAnimating == false)
        #expect(window.isUserInteractionEnabled == true)
    }

    @Test("present: sets the title view and left bar button menu item according to the state")
    func presentAll() async throws {
        subject.loadViewIfNeeded()
        let state = ArtistsState(listType: .allArtists)
        await subject.present(state)
        let label = try #require(subject.navigationItem.titleView as? UILabel)
        #expect(label.text == "Artists")
        #expect(label.font == UIFont(name: "Verdana-Bold", size: 17))
        #expect(label.textAlignment == .center)
        #expect(Float(label.minimumScaleFactor) == 0.8 as Float) // eliminate tiny difference
        #expect(label.adjustsFontSizeToFitWidth == true)
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 3)
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
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[2]
            #expect(action.title == "Server")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .server)
        }
    }

    @Test("present: sets the title and left bar button menu item according to the state")
    func presentComposers() async throws {
        subject.loadViewIfNeeded()
        let state = ArtistsState(listType: .composers)
        await subject.present(state)
        let label = try #require(subject.navigationItem.titleView as? UILabel)
        #expect(label.text == "Composers")
        #expect(label.font == UIFont(name: "Verdana-Bold", size: 17))
        #expect(label.textAlignment == .center)
        #expect(Float(label.minimumScaleFactor) == 0.8 as Float) // eliminate tiny difference
        #expect(label.adjustsFontSizeToFitWidth == true)
        let menu = try #require(subject.navigationItem.leftBarButtonItem?.menu)
        #expect(menu.children.count == 3)
        do {
            let action = menu.children[0]
            #expect(action.title == "Artists")
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
        processor.thingsReceived.removeAll()
        do {
            let action = menu.children[2]
            #expect(action.title == "Server")
            (action as! UIMenuLeaf).performWithSender(nil, target: nil)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived.last == .server)
        }
    }

    @Test("showPlaylist: sends showPlaylist to processor")
    func showPlaylist() async {
        subject.showPlaylist()
        await #while(processor.thingsReceived.last != .showPlaylist)
        #expect(processor.thingsReceived.last == .showPlaylist)
    }
}
