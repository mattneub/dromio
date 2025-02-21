@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct AlbumsViewControllerTests {
    let subject = AlbumsViewController(nibName: nil, bundle: nil)
    let mockDataSourceDelegate = MockDataSourceDelegate<AlbumsState, AlbumsAction>(tableView: UITableView())
    let processor = MockReceiver<AlbumsAction>()

    init() {
        subject.dataSourceDelegate = mockDataSourceDelegate
        subject.processor = processor
    }

    @Test("Initialize: sets title to Albums, creates data source delegate")
    func initialize() throws {
        let subject = AlbumsViewController(nibName: nil, bundle: nil)
        #expect(subject.title == "Albums")
        #expect(subject.dataSourceDelegate != nil)
    }

    @Test("Setting the processor sets the data source's processor")
    func setProcessor() {
        let processor2 = MockReceiver<AlbumsAction>()
        subject.processor = processor2
        #expect(mockDataSourceDelegate.processor === processor2)
    }

    @Test("viewDidLoad: sets the data source's processor, sets background color, sends .initialData action")
    func viewDidLoad() async {
        subject.loadViewIfNeeded()
        #expect(mockDataSourceDelegate.processor === subject.processor)
        #expect(subject.view.backgroundColor == .green)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .initialData)
    }

    @Test("present: presents to the data source")
    func present() {
        let state = AlbumsState(albums: [.init(id: "1", name: "name", songCount: 10)])
        subject.present(state)
        #expect(mockDataSourceDelegate.methodsCalled.last == "present(_:)")
        #expect(mockDataSourceDelegate.state == state)
    }
}
