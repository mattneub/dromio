@testable import Dromio
import Testing
import Foundation

@MainActor
struct PingProcessorTests {
    let subject = PingProcessor()
    let presenter = MockReceiverPresenter<PingAction, PingState>()
    let networker = MockNetworker()

    init() {
        services.networker = networker
        subject.presenter = presenter
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
        #expect(networker.methodsCalled == ["ping()"])
    }

    @Test("receive doPing: calls networker ping, sets state success to .success if no throw")
    func receiveDoPingSuccess() async {
        networker.pingError = nil
        await subject.receive(.doPing)
        #expect(networker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .success)
    }

    @Test("receive doPing: calls networker ping, sets state success to .failure and message if throw NetworkerError")
    func receiveDoPingFailure() async {
        networker.pingError = NetworkerError.message("test")
        await subject.receive(.doPing)
        #expect(networker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "test"))
    }

    @Test("receive doPing: calls networker ping, sets state success to .failure and localized description if throw other error")
    func receiveDoPingFailure2() async {
        class MyError: NSError, @unchecked Sendable {
            override var localizedDescription: String { "oops" }
        }
        networker.pingError = MyError(domain: "domain", code: 0)
        await subject.receive(.doPing)
        #expect(networker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == .failure(message: "oops"))
    }
}
