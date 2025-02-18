@testable import Dromio
import Testing

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
        subject.state.success = true
        #expect(presenter.statePresented?.success == true)
    }

    @Test("receive doPing: calls networker ping")
    func receiveDoPing() async {
        await subject.receive(.doPing)
        #expect(networker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == false)
    }

    @Test("receive doPing: calls networker ping, sets state success to true if result is true")
    func receiveDoPingSuccess() async {
        networker.valueToReturnFromPing = true
        await subject.receive(.doPing)
        #expect(networker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.success == true)
    }
}
