@testable import Dromio
import Testing
import WaitWhile
import UIKit

@MainActor
struct ServerViewControllerTests {
    let subject = ServerViewController(nibName: "Server", bundle: nil)
    let processor = MockProcessor<ServerAction, ServerState>()

    init() {
        subject.processor = processor
    }

    @Test("receive alertWithMessage: puts up alert with message")
    func receiveAlert() async throws {
        makeWindow(viewController: subject)
        await subject.receive(.alertWithMessage("Hello!"))
        await #while(subject.presentedViewController == nil)
        let alert = try #require(subject.presentedViewController as? UIAlertController)
        #expect(alert.title == "Error")
        #expect(alert.message == "Hello!")
    }

    @Test("textFieldChanged: sends textFieldChanged with field and text, host")
    func textFieldChangedHost() async {
        makeWindow(viewController: subject)
        subject.host.text = "host"
        subject.textFieldChanged(subject.host)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .textFieldChanged(.host, "host"))
    }

    @Test("textFieldChanged: sends textFieldChanged with field and text, port")
    func textFieldChangedPort() async {
        makeWindow(viewController: subject)
        subject.port.text = "port"
        subject.textFieldChanged(subject.port)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .textFieldChanged(.port, "port"))
    }

    @Test("textFieldChanged: sends textFieldChanged with field and text, username")
    func textFieldChangedUsername() async {
        makeWindow(viewController: subject)
        subject.username.text = "username"
        subject.textFieldChanged(subject.username)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .textFieldChanged(.username, "username"))
    }

    @Test("textFieldChanged: sends textFieldChanged with field and text, password")
    func textFieldChangedPassword() async {
        makeWindow(viewController: subject)
        subject.password.text = "password"
        subject.textFieldChanged(subject.password)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .textFieldChanged(.password, "password"))
    }

    @Test("segmentedControlChanged: sends schemeChanged with scheme, http")
    func segmentedControllerChangedHttp() async {
        makeWindow(viewController: subject)
        subject.scheme.selectedSegmentIndex = 0
        subject.segmentedControlChanged(subject.scheme)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .schemeChanged(.http))
    }

    @Test("segmentedControlChanged: sends schemeChanged with scheme, https")
    func segmentedControllerChangedHttps() async {
        makeWindow(viewController: subject)
        subject.scheme.selectedSegmentIndex = 1
        subject.segmentedControlChanged(subject.scheme)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .schemeChanged(.https))
    }

    @Test("doDone: sends done")
    func doDone() async {
        subject.doDone("howdy")
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.first == .done)
    }
}
