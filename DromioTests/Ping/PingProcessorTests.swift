@testable import Dromio
import Testing
import Foundation

@MainActor
struct PingProcessorTests {
    let subject = PingProcessor()
    let presenter = MockReceiverPresenter<PingAction, PingState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()

    init() {
        services.requestMaker = requestMaker
        subject.presenter = presenter
        subject.coordinator = coordinator
    }

    @Test("changing the state presents the state")
    func changeState() {
        #expect(presenter.statePresented == nil)
        subject.state.success = .success
        #expect(presenter.statePresented?.success == .success)
    }

    @Test("receive doPing: calls networker ping")
    func receiveDoPing() async {
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
    }

    @Test("receive doPing: calls networker ping, sets state success to .success if no throw and calls coordinator showAlbums")
    func receiveDoPingSuccess() async {
        requestMaker.pingError = nil
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(presenter.statePresented?.success == .success)
        #expect(coordinator.methodsCalled[0] == "showAlbums()")
    }

    @Test("receive doPing: calls networker ping, sets state success to .failure and message if throw NetworkerError")
    func receiveDoPingFailure() async {
        requestMaker.pingError = NetworkerError.message("test")
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "test"))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive doPing: calls networker ping, sets state success to .failure and localized description if throw other error")
    func receiveDoPingFailure2() async {
        class MyError: NSError, @unchecked Sendable {
            override var localizedDescription: String { "oops" }
        }
        requestMaker.pingError = MyError(domain: "domain", code: 0)
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "oops"))
        #expect(coordinator.methodsCalled.isEmpty)
    }
}
