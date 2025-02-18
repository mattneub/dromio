@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PingViewControllerTests {
    let subject = PingViewController(nibName: "Ping", bundle: nil)
    let processor = MockProcessor<PingAction, PingState>()

    init() {
        subject.processor = processor
    }

    @Test("viewDidLoad: sets title and background color, success label is hidden")
    func viewDidLoad() {
        subject.loadViewIfNeeded()
        #expect(subject.title == "Ping")
        #expect(subject.view.backgroundColor == .systemBackground)
        #expect(subject.successLabel.isHidden)
    }

    @Test("viewDidAppear: sends doPing to processor")
    func viewDidAppear() async {
        subject.viewDidAppear(false)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.doPing])
    }
}
