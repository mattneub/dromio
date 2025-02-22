@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumViewControllerTests {
    let subject = AlbumViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumState, AlbumAction>(tableView: UITableView())
    let processor = MockReceiver<AlbumAction>()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
    }

    @Test("Initialize: creates data source delegate")
    func initialize() throws {
        let subject = AlbumViewController(nibName: nil, bundle: nil)
        #expect(subject.dataSourceDelegate != nil)
        #expect(subject.dataSourceDelegate?.tableView === subject.tableView)
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
        #expect(subject.view.backgroundColor == .red)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
    }

    @Test("present: presents to the data source")
    func present() {
        let state = AlbumState(songs: [.init(id: "1", title: "Title", artist: "Artist", track: 1, albumId: "2")])
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }
}
