@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PingViewControllerTests {
    let subject = PingViewController(nibName: "Ping", bundle: nil)
    let processor = MockAsyncProcessor<PingAction, PingState, Void>()

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
        #expect(subject.offlineModeButton.isHidden)
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
    func present() async {
        subject.loadViewIfNeeded()

        await subject.present(.init(status: .empty))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .unknown))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .success))
        #expect(!subject.pingingLabel.isHidden)
        #expect(!subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .failure(message: "oops")))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(!subject.failureLabel.isHidden)
        #expect(subject.failureLabel.text == "oops")
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)
        #expect(!subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .choices))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)
        #expect(!subject.offlineModeButton.isHidden)
    }

    @Test("doReenterButton: sends processor reenterServerInfo")
    func doReenterButton() async {
        subject.doReenterButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.reenterServerInfo])
    }

    @Test("doPickServerButton: sends processor pickServer")
    func doPickServerButton() async {
        subject.doPickServerButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.pickServer])
    }

    @Test("doDeleteServerButton: sends processor deleteServer")
    func doDeleteServerButton() async {
        subject.doDeleteServerButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deleteServer])
    }

    @Test("doOfflineModeButton: sends processor offlineMode")
    func doOfflineModeButton() async {
        subject.doOfflineModeButton(UIButton())
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.offlineMode])
    }
}
