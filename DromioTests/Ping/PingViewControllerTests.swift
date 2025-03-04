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
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
    }

    @Test("viewDidAppear: sends doPing to processor")
    func viewDidAppear() async {
        subject.viewDidAppear(false)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.doPing])
    }

    @Test("present: sets the two labels and button as expected")
    func present() {
        subject.loadViewIfNeeded()
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        subject.present(.init(success: .success))
        #expect(!subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        subject.present(.init(success: .failure(message: "oops")))
        #expect(subject.successLabel.isHidden)
        #expect(!subject.failureLabel.isHidden)
        #expect(subject.failureLabel.text == "oops")
        #expect(!subject.reenterButton.isHidden)
    }

    @Test("doReenterButton: sends processor reenterServerInfo")
    func doReenterButton() async {
        subject.doReenterButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.reenterServerInfo])
    }
}
