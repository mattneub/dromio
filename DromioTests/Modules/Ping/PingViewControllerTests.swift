@testable import Dromio
import Testing
import UIKit
import WaitWhile

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
        #expect(subject.offlineModeButton.isHidden)
    }

    @Test("viewDidLoad: sets up button update configuration handlers")
    func viewDidLoad() throws {
        subject.loadViewIfNeeded()
        for button in [subject.reenterButton, subject.pickServerButton, subject.pickFolderButton, subject.deleteServerButton, subject.offlineModeButton] {
            let button = try #require(button)
            #expect(button.configurationUpdateHandler != nil)
            #expect(button.configuration?.background.backgroundColor == .systemTeal)
            button.isHighlighted = true
            button.configurationUpdateHandler?(button)
            #expect(button.configuration?.background.backgroundColor == .systemTeal.withAlphaComponent(0.6))
            button.isHighlighted = false
            button.isEnabled = false
            button.configurationUpdateHandler?(button)
            #expect(button.configuration?.background.backgroundColor == .systemGray3.withAlphaComponent(0.7))
        }
    }

    @Test("viewIsAppearing: sends launch to processor the first time, then choices")
    func viewIsAppearing() async {
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.launch])
        subject.viewIsAppearing(false)
        await #while(processor.thingsReceived == [.launch])
        #expect(processor.thingsReceived == [.launch, .choices])
    }

    @Test("present: sets the labels and buttons as expected")
    func present() async {
        subject.loadViewIfNeeded()

        await subject.present(.init(status: .empty))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickFolderButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .unknown))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickFolderButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .success))
        #expect(!subject.pingingLabel.isHidden)
        #expect(!subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(subject.reenterButton.isHidden)
        #expect(subject.pickFolderButton.isHidden)
        #expect(subject.pickServerButton.isHidden)
        #expect(subject.deleteServerButton.isHidden)
        #expect(subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .failure(message: "oops")))
        #expect(!subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(!subject.failureLabel.isHidden)
        #expect(subject.failureLabel.text == "oops")
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickFolderButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)
        #expect(!subject.offlineModeButton.isHidden)

        await subject.present(.init(status: .choices))
        #expect(subject.pingingLabel.isHidden)
        #expect(subject.successLabel.isHidden)
        #expect(subject.failureLabel.isHidden)
        #expect(!subject.reenterButton.isHidden)
        #expect(!subject.pickFolderButton.isHidden)
        #expect(!subject.pickServerButton.isHidden)
        #expect(!subject.deleteServerButton.isHidden)
        #expect(!subject.offlineModeButton.isHidden)
    }

    @Test("present: enables the pickFolderButton as expected")
    func presentPickFolderButton() async {
        subject.loadViewIfNeeded()

        await subject.present(.init(status: .empty, enablePickFolderButton: true))
        #expect(!subject.pickFolderButton.isEnabled)

        await subject.present(.init(status: .choices, enablePickFolderButton: false))
        #expect(!subject.pickFolderButton.isEnabled)

        await subject.present(.init(status: .choices, enablePickFolderButton: true))
        #expect(subject.pickFolderButton.isEnabled)
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
