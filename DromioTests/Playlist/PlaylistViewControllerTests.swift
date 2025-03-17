@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PlaylistViewControllerTests {
    let subject = PlaylistViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<PlaylistState, PlaylistAction, PlaylistEffect>(tableView: UITableView())
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

    @Test("table header view is created only iff user has jukebox role")
    func tableHeaderView() {
        // this test has been altered: we currently expect no table view header no matter what
        userHasJukeboxRole = false
        var subject = PlaylistViewController(nibName: nil, bundle: nil)
        #expect(subject.tableView.tableHeaderView == nil)
        userHasJukeboxRole = true
        subject = PlaylistViewController(nibName: nil, bundle: nil)
        // #expect(subject.tableView.tableHeaderView === subject.tableHeaderView)
        #expect(subject.tableView.tableHeaderView == nil)
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
                duration: nil,
                contributors: nil
            )]
        )
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }

    // Withdrawn, there is no such header currently
    /*
    @Test("present: sets the image of the jukebox button in the table view header")
    func presentJukeboxButton() async throws {
        userHasJukeboxRole = true
        let subject = PlaylistViewController(nibName: nil, bundle: nil)
        let button = try #require(subject.tableView.tableHeaderView?.subviews(ofType: UIButton.self).first)
        #expect(button.configuration?.image == UIImage(systemName: "rectangle"))
        var state = PlaylistState(jukebox: true, songs: [])
        subject.present(state)
        #expect(button.configuration?.image == UIImage(systemName: "checkmark.rectangle"))
        state = PlaylistState(jukebox: false, songs: [])
        subject.present(state)
        #expect(button.configuration?.image == UIImage(systemName: "rectangle"))
    }
     */

    @Test("receive deselectAll: tells the table view to select nil")
    func receiveDeselectAll() async {
        subject.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        #expect(subject.tableView.indexPathForSelectedRow != nil)
        await subject.receive(.deselectAll)
        #expect(subject.tableView.indexPathForSelectedRow == nil)
    }

    @Test("receive progress: passes it to the datasource")
    func receiveProgress() async {
        await subject.receive(.progress("1", 0.5))
        #expect(mockDataSourceDelegate.thingsReceived.last == .progress("1", 0.5))
    }

    @Test("doClear: sends .clear to the processor")
    func doClear() async {
        subject.doClear()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .clear)
    }

    @Test("jukebox button sends .jukeboxButton to processor")
    func doJukeboxButton() async throws {
        let button = try #require(subject.tableHeaderView.subviews(ofType: UIButton.self).first)
        button.performPrimaryAction()
        await #while(processor.thingsReceived.last != .jukeboxButton)
        #expect(processor.thingsReceived.last == .jukeboxButton)
    }
}
