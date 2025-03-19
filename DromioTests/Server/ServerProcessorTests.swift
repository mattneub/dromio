@testable import Dromio
import Testing
import WaitWhile

@MainActor
struct ServerProcessorTests {
    let subject = ServerProcessor()
    let presenter = MockReceiverPresenter<Void, ServerState>()
    let urlMaker = MockURLMaker()
    let persistence = MockPersistence()
    let coordinator = MockRootCoordinator()
    let delegate = MockServerDelegate()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        services.urlMaker = urlMaker
        services.persistence = persistence
        subject.delegate = delegate
    }

    @Test("mutating state presents, but if `noPresentation` flag, does not present and resets the flag")
    func mutatingState() {
        subject.state.host = "host"
        #expect(presenter.statePresented?.host == "host")
        subject.noPresentation = true
        subject.state.host = ""
        #expect(presenter.statePresented?.host == "host")
        #expect(presenter.statesPresented.count == 1)
    }

    @Test("receive schemeChanged: sets the state scheme without presenting")
    func receiveSchemeChanged() async {
        await subject.receive(.schemeChanged(.https))
        #expect(subject.state.scheme == .https)
        #expect(presenter.statePresented == nil)
    }

    @Test("receive textFieldChanged: sets the right propery of the state without presenting")
    func receiveTextFieldChanged() async {
        await subject.receive(.textFieldChanged(.host, "host"))
        #expect(subject.state.host == "host")
        #expect(presenter.statePresented == nil)
        await subject.receive(.textFieldChanged(.password, "password"))
        #expect(subject.state.password == "password")
        #expect(presenter.statePresented == nil)
        await subject.receive(.textFieldChanged(.username, "username"))
        #expect(subject.state.username == "username")
        #expect(presenter.statePresented == nil)
        await subject.receive(.textFieldChanged(.port, "port"))
        #expect(subject.state.port == "port")
        #expect(presenter.statePresented == nil)
    }

    @Test("receive done: makes the correct ServerInfo, calls dismissToPing, passes the server info to delegate `userEdited`")
    func doDone() async {
        subject.state = .init(
            scheme: .http,
            host: "host",
            port: "1234",
            username: "username",
            password: "password"
        )
        let expected = ServerInfo(
            scheme: "http",
            host: "host",
            port: 1234,
            username: "username",
            password: "password",
            version: "1.16.1"
        )
        await subject.receive(.done)
        #expect(coordinator.methodsCalled == ["dismissToPing()"])
        #expect(delegate.methodsCalled == ["userEdited(serverInfo:)"])
        #expect(delegate.serverInfo == expected)
    }

    @Test("receive done: makes the correct ServerInfo with https, calls dismissToPing, passes the server info to delegate `userEdited`")
    func doDoneHttps() async {
        subject.state = .init(
            scheme: .https,
            host: "host",
            port: "1234",
            username: "username",
            password: "password"
        )
        let expected = ServerInfo(
            scheme: "https",
            host: "host",
            port: 1234,
            username: "username",
            password: "password",
            version: "1.16.1"
        )
        await subject.receive(.done)
        #expect(coordinator.methodsCalled == ["dismissToPing()"])
        #expect(delegate.methodsCalled == ["userEdited(serverInfo:)"])
        #expect(delegate.serverInfo == expected)
    }

    @Test("receive done: if ServerInfo throws empty host, sends showAlert to coordinator")
    func doDoneEmptyHost() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "",
            port: "1234",
            username: "username",
            password: "password"
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "The host cannot be empty.")
    }

    @Test("receive done: if ServerInfo throws invalidURL, sends sends showAlert to coordinator")
    func doDoneBadURL() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "$*?",
            port: "1234",
            username: "username",
            password: "password"
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "A valid URL could not be constructed.")
    }

    @Test("receive done: if ServerInfo throws password empty, sends sends showAlert to coordinator")
    func doDoneEmptyPassword() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "host",
            port: "1234",
            username: "username",
            password: ""
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "The password cannot be empty.")
    }

    @Test("receive done: if ServerInfo throws port empty, sends sends showAlert to coordinator")
    func doDoneEmptyPort() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "host",
            port: "",
            username: "username",
            password: "password"
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "The port cannot be empty.")
    }

    @Test("receive done: if ServerInfo throws port not number, sends sends showAlert to coordinator")
    func doDoneNonnumericPort() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "host",
            port: "port",
            username: "username",
            password: "password"
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "The port must be a number (an integer).")
    }

    @Test("receive done: if ServerInfo throws username empty, sends sends showAlert to coordinator")
    func doDoneEmptyUsername() async {
        let info = urlMaker.currentServerInfo
        subject.state = .init(
            scheme: .https,
            host: "host",
            port: "1234",
            username: "",
            password: "password"
        )
        await subject.receive(.done)
        #expect(persistence.methodsCalled == [])
        #expect(persistence.servers == nil)
        #expect(urlMaker.currentServerInfo == info)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Error")
        #expect(coordinator.message == "The username cannot be empty.")
    }

    // I don't know how to test the bad scheme message, I don't think it can happen.
}
