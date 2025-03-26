@testable import Dromio
import Testing
import UIKit
import WaitWhile
import SnapshotTesting

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
        #expect(subject.title == "Queue")
    }

    @Test("The jukebox button is correctly configured")
    func jukeboxButton() async throws {
        let button = subject.jukeboxButton
        let viewController = UIViewController()
        viewController.view.addSubview(button)
        makeWindow(viewController: viewController)
        let configuration = try #require(button.configuration)
        #expect(configuration.attributedTitle == AttributedString("Jukebox Mode: ", attributes: .init ([
            .font: UIFont(name: "GillSans-Bold", size: 15) as Any,
            .foregroundColor: UIColor.label,
        ])))
        #expect(button.titleLabel?.textColor == .label)
        #expect(configuration.image == UIImage(systemName: "rectangle"))
        #expect(button.imageView?.tintColor == .label)
        #expect(configuration.imagePlacement == .trailing)
        button.isEnabled = false
        await #while(button.imageView?.tintColor == .label)
        #expect(button.imageView?.tintColor == .systemGray)
        #expect(button.titleLabel?.textColor == .systemGray)
    }

    @Test("The table header view is correctly constructed")
    func tableHeaderViewAppearance() throws {
        #expect(subject.tableHeaderView.backgroundColor == .background)
        let button = try #require(subject.tableHeaderView.subviews.first as? UIButton)
        #expect(button === subject.jukeboxButton)
        subject.tableHeaderView.bounds = CGRect(origin: .zero, size: .init(width: 600, height: 400))
        assertSnapshot(of: subject.tableHeaderView, as: .image)
    }

    @Test("table header view is created only iff user has jukebox role")
    func tableHeaderViewJukebox() {
        userHasJukeboxRole = false
        var subject = PlaylistViewController(nibName: nil, bundle: nil)
        #expect(subject.tableView.tableHeaderView == nil)
        userHasJukeboxRole = true
        subject = PlaylistViewController(nibName: nil, bundle: nil)
        #expect(subject.tableView.tableHeaderView === subject.tableHeaderView)
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
        #expect(subject.view.backgroundColor == .background)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
    }

    @Test("viewDidLoad: creates right bar button item")
    func viewDidLoadRight() async throws {
        subject.loadViewIfNeeded()
        let rightBarButtonItem = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(rightBarButtonItem.image == UIImage(systemName: "clear.fill"))
        #expect(rightBarButtonItem.target === subject)
        #expect(rightBarButtonItem.action == #selector(subject.doClear))
    }

    @Test("viewDidLoad: creates the other right bar button item")
    func viewDidLoadRight2() async throws {
        subject.loadViewIfNeeded()
        let playpauseButtonItem = try #require(subject.navigationItem.rightBarButtonItems?[1])
        #expect(playpauseButtonItem.image == UIImage(systemName: "playpause.fill"))
        #expect(playpauseButtonItem.target === subject)
        #expect(playpauseButtonItem.action == #selector(subject.doPlayPause))
        #expect(playpauseButtonItem.width == 40)
        #expect(playpauseButtonItem.isSymbolAnimationEnabled == true)
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

    @Test("present: sets the image of the jukebox button in the table view header")
    func presentJukeboxButton() async throws {
        userHasJukeboxRole = true
        let subject = PlaylistViewController(nibName: nil, bundle: nil)
        let button = try #require(subject.tableView.tableHeaderView?.subviews(ofType: UIButton.self).first)
        #expect(button.configuration?.image == UIImage(systemName: "rectangle"))
        var state = PlaylistState(jukeboxMode: true, songs: [])
        subject.present(state)
        #expect(button.configuration?.image == UIImage(systemName: "checkmark.rectangle"))
        state = PlaylistState(jukeboxMode: false, songs: [])
        subject.present(state)
        #expect(button.configuration?.image == UIImage(systemName: "rectangle"))
    }

    @Test("present: sets enablement of the playpause button")
    func presentPlaypauseButton() async throws {
        let items = try #require(subject.navigationItem.rightBarButtonItems)
        var state = PlaylistState()
        state.jukeboxMode = false
        state.currentSongId = nil
        subject.present(state)
        #expect(!items[1].isEnabled)
        state.jukeboxMode = true
        state.currentSongId = nil
        subject.present(state)
        #expect(!items[1].isEnabled)
        state.jukeboxMode = false
        state.currentSongId = "1"
        subject.present(state)
        #expect(items[1].isEnabled)
        state.jukeboxMode = true
        state.currentSongId = "1"
        subject.present(state)
        #expect(!items[1].isEnabled)
    }

    @Test("present: sets enablement of clear button")
    func presentClearButton() async throws {
        let items = try #require(subject.navigationItem.rightBarButtonItems)
        var state = PlaylistState()
        state.offlineMode = false
        subject.present(state)
        #expect(items[0].isEnabled)
        state.offlineMode = true
        subject.present(state)
        #expect(!items[0].isEnabled)
    }

    @Test("present: sets visibility of jukeboxButton")
    func presentJukeboxButtonVisibility() async throws {
        let button = subject.jukeboxButton
        var state = PlaylistState()
        state.offlineMode = false
        subject.present(state)
        #expect(button.isEnabled)
        state.offlineMode = true
        subject.present(state)
        #expect(!button.isEnabled)
    }

    @Test("receive deselectAll: tells the table view to select nil")
    func receiveDeselectAll() async {
        subject.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        #expect(subject.tableView.indexPathForSelectedRow != nil)
        await subject.receive(.deselectAll)
        #expect(subject.tableView.indexPathForSelectedRow == nil)
    }

    @Test("receive playerState: sets the symbol image of the second right bar button item")
    func receivePlayerState() async throws {
        subject.loadViewIfNeeded()
        let button = try #require(subject.navigationItem.rightBarButtonItems?[1])
        await subject.receive(.playerState(.playing))
        await #while(button.image == UIImage(systemName: "playpause.fill"))
        #expect(button.image == UIImage(systemName: "pause.fill"))
        await subject.receive(.playerState(.paused))
        await #while(button.image == UIImage(systemName: "pause.fill"))
        #expect(button.image == UIImage(systemName: "play.fill"))
        await subject.receive(.playerState(.empty))
        await #while(button.image == UIImage(systemName: "play.fill"))
        #expect(button.image == UIImage(systemName: "playpause.fill"))
    }

    @Test("receive progress: passes it to the datasource")
    func receiveProgress() async {
        await subject.receive(.progress("1", 0.5))
        #expect(mockDataSourceDelegate.thingsReceived.last == .progress("1", 0.5))
    }

    @Test("doPlayPause: sends .playPause to the processor")
    func doPlayPause() async {
        subject.doPlayPause()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .playPause)
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
