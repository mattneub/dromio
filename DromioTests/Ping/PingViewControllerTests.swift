@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PingViewControllerTests {
    let subject = PingViewController(nibName: "Ping", bundle: nil)
    let processor = MockProcessor<PingAction, PingState, Void>()

    init() {
        subject.processor = processor
    }

    @Test("subviews are initially all hidden")
    func subviewsHidden() {
        subject.loadViewIfNeeded()
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
    }

    @Test("viewIsAppearing: sends doPing to processor the first time, then choices")
    func viewIsAppearing() async {
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.doPing])
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived == [.doPing])
        #expect(processor.thingsReceived == [.doPing, .choices])
    }

    @Test("present: sets the labels and buttons as expected")
    func present() {
        subject.loadViewIfNeeded()

        subject.present(.init(status: .empty))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)

        subject.present(.init(status: .unknown))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)

        subject.present(.init(status: .success))
        #expect(!subject.pingingLabel.isHidden)
        #expect(!subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)

        subject.present(.init(status: .failure(message: "oops")))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(!subject.failureLabel.isHidden)
        #expect(subject.failureLabel.text == "oops")
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)

        subject.present(.init(status: .choices))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)
    }

    @Test("doReenterButton: sends processor reenterServerInfo")
    func doReenterButton() async {
        subject.doReenterButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.reenterServerInfo])
    }

    @Test("doPickServerButton: sends processor reenterServerInfo")
    func doPickServerButton() async {
        subject.doPickServerButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.pickServer])
    }

    @Test("doDeleteServerButton: sends processor reenterServerInfo")
    func doDeleteServerButton() async {
        subject.doDeleteServerButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deleteServer])
    }
}
