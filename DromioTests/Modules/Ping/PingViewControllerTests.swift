@testable import Dromio
import Testing
import UIKit

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
    func viewIsAppearing() {
        subject.viewIsAppearing(false)
        #expect(processor.thingsReceived == [.launch])
        subject.viewIsAppearing(false)
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
    func doReenterButton() {
        subject.doReenterButton(UIButton())
        #expect(processor.thingsReceived == [.reenterServerInfo])
    }

    @Test("doPickServerButton: sends processor pickServer")
    func doPickServerButton() {
        subject.doPickServerButton(UIButton())
        #expect(processor.thingsReceived == [.pickServer])
    }

    @Test("doPickFolderButton: sends processor pickFolder")
    func doPickFolderButton() {
        subject.doPickFolderButton(UIButton())
        #expect(processor.thingsReceived == [.pickFolder])
    }

    @Test("doDeleteServerButton: sends processor deleteServer")
    func doDeleteServerButton() {
        subject.doDeleteServerButton(UIButton())
        #expect(processor.thingsReceived == [.deleteServer])
    }

    @Test("doOfflineModeButton: sends processor offlineMode")
    func doOfflineModeButton() {
        subject.doOfflineModeButton(UIButton())
        #expect(processor.thingsReceived == [.offlineMode])
    }
}
