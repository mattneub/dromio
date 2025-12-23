@testable import Dromio
import Testing
import UIKit
import WaitWhile

struct AlbumViewControllerTests {
    let subject = AlbumViewController()
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumState, AlbumAction, Void>(tableView: UITableView())
    let processor = MockReceiver<AlbumAction>()
    let tableView = MockTableView()
    let configurator = MockSearchConfigurator()

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

    @Test("viewDidLoad: sets background color, sets spinner, calls search configurator, configures table, right bbi")
    func viewDidLoad() async throws {
        subject.loadViewIfNeeded()
        #expect(subject.dataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .background)
        #expect(subject.activity.isDescendant(of: subject.view))
        #expect(configurator.methodsCalled == ["configure(viewController:updater:)"])
        #expect(configurator.viewController === subject)
        #expect(configurator.updater === mockDataSourceDelegate)
        #expect(subject.tableView.estimatedRowHeight == 90)
        #expect(subject.tableView.sectionHeaderTopPadding == 0)
        let item = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(item.target === subject)
        #expect(item.action == #selector(subject.showPlaylist))
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
        #expect(tableView.methodsCalled.last == "scrollToRow(at:at:animated:)")
        #expect(tableView.contentOffset.y == -20)
    }

    @Test("receive scrollToZero: does nothing if there are no cells")
    func scrollToZeroNoCells() async {
        // in order to test this we practically have to build that actual app!
        subject.tableView = tableView // who knew you could do that?
        subject.dataSourceDelegate = AlbumDataSourceDelegate(tableView: tableView)
        let songs = [SubsonicSong]()
        makeWindow(viewController: subject)
        await subject.present(.init(songs: songs))
        // that was prep, this is the test
        await subject.receive(.scrollToZero)
        #expect(!tableView.methodsCalled.contains("scrollToRow(at:at:animated:)"))
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

    @Test("present: configures the title view as label")
    func presentTitleView() async throws {
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
        let label = try #require(subject.navigationItem.titleView as? UILabel)
        #expect(label.text == "Album")
        #expect(label.font == UIFont(name: "Verdana-Bold", size: 17))
        #expect(label.numberOfLines == 2)
        #expect(label.textAlignment == .center)
        #expect(Float(label.minimumScaleFactor) == 0.8 as Float) // eliminate tiny difference
        #expect(label.adjustsFontSizeToFitWidth == true)
        let constraint = try #require(label.constraints.first)
        #expect(constraint.firstAttribute == .width)
        #expect(constraint.priority == .init(500))
        #expect(constraint.constant == 200)
        #expect(constraint.isActive)
    }

    @Test("receive animatePlaylist: tells the playlist bar button item to animate")
    func receiveAnimatePlaylist() throws {
        // I don't see how to test this: you can't ask a bar button item whether it has a symbol effect
    }

    @Test("receive animateSong: calls `indexPath(forDatum:), animates")
    func receiveAnimateSong() async throws {
        let song = SubsonicSong(
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
        )
        await subject.receive(.animate(song: song))
        #expect(mockDataSourceDelegate.methodsCalled.last == "indexPath(forDatum:)")
        #expect(mockDataSourceDelegate.datum == "1")
        // And I don't know how to test the animation.
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
