@testable import Dromio
import Testing
import Foundation

@MainActor
struct PingProcessorTests {
    let subject = PingProcessor()
    let presenter = MockReceiverPresenter<Void, PingState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()
    let urlMaker = MockURLMaker()
    let persistence = MockPersistence()

    init() {
        services.requestMaker = requestMaker
        services.urlMaker = urlMaker
        services.persistence = persistence
        subject.presenter = presenter
        subject.coordinator = coordinator
    }

    @Test("changing the state presents the state")
    func changeState() {
        #expect(presenter.statePresented == nil)
        subject.state.success = .success
        #expect(presenter.statePresented?.success == .success)
    }

    @Test("receive doPing: if current server is nil, tries to load the server")
    func receiveDoPingNilCurrentServer() async {
        await subject.receive(.doPing)
        #expect(persistence.methodsCalled[0] == "loadServers()")
    }

    @Test("receive doPing: if current server is nil, and there is no stored server, shows the server interface")
    func receiveDoPingNilCurrentServerNoStored() async {
        await subject.receive(.doPing)
        #expect(coordinator.methodsCalled[0] == "showServer()")
    }

    @Test("receive doPing: if current server is nil, and there is a stored server, sets current server to it")
    func receiveDoPingNilCurrentServerStored() async {
        let server = ServerInfo.init(
            scheme: "http",
            host: "h",
            port: 1,
            username: "u",
            password: "p",
            version: "v"
        )
        persistence.servers = [server]
        await subject.receive(.doPing)
        #expect(!coordinator.methodsCalled.contains("showServer()"))
        #expect(urlMaker.currentServerInfo == server)
    }

    @Test("receive doPing: with current server calls networker ping")
    func receiveDoPing() async {
        let server = ServerInfo.init(
            scheme: "http",
            host: "h",
            port: 1,
            username: "u",
            password: "p",
            version: "v"
        )
        persistence.servers = [server]
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
    }

    @Test("receive doPing: with current server calls networker ping, sets state success to .success if no throw and calls coordinator showAlbums")
    func receiveDoPingSuccess() async {
        let server = ServerInfo.init(
            scheme: "http",
            host: "h",
            port: 1,
            username: "u",
            password: "p",
            version: "v"
        )
        persistence.servers = [server]
        requestMaker.pingError = nil
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(presenter.statePresented?.success == .success)
        #expect(coordinator.methodsCalled[0] == "showAlbums()")
    }

    @Test("receive doPing: with current server calls networker ping, sets state success to .failure and message if throw NetworkerError")
    func receiveDoPingFailure() async {
        let server = ServerInfo.init(
            scheme: "http",
            host: "h",
            port: 1,
            username: "u",
            password: "p",
            version: "v"
        )
        persistence.servers = [server]
        requestMaker.pingError = NetworkerError.message("test")
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "test"))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive doPing: with current server calls networker ping, sets state success to .failure and localized description if throw other error")
    func receiveDoPingFailure2() async {
        class MyError: NSError, @unchecked Sendable {
            override var localizedDescription: String { "oops" }
        }
        let server = ServerInfo.init(
            scheme: "http",
            host: "h",
            port: 1,
            username: "u",
            password: "p",
            version: "v"
        )
        persistence.servers = [server]
        requestMaker.pingError = MyError(domain: "domain", code: 0)
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "oops"))
        #expect(coordinator.methodsCalled.isEmpty)
    }
}
