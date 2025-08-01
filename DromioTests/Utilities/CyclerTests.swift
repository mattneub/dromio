@testable import Dromio
import Testing

@MainActor struct CyclerTests {
    enum MyAction: Equatable {
        case assoc(Int)
        case plain
    }

    @Test("Cycler forwards received actions")
    func cycler() async {
        let processor = MockProcessor<MyAction, Void, Void>()
        let subject = Cycler(processor: processor)
        await subject.receive(.plain)
        #expect(processor.thingsReceived == [.plain])
        await subject.receive(.assoc(1))
        #expect(processor.thingsReceived == [.plain, .assoc(1)])
        await subject.receive(.assoc(2))
        #expect(processor.thingsReceived == [.plain, .assoc(1), .assoc(2)])
    }
}

