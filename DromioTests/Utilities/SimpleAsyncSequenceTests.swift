@testable import Dromio
import Testing
import Foundation

struct SimpleAsyncSequenceTests {
    @Test("Initializer: forms a correct sequence")
    func initializer() async {
        let subject = SimpleAsyncSequence(array: [1, 2, 3])
        let result = subject.map { i in
            let task = Task { i*2 }
            return await task.value
        }
        var expected = [2, 4, 6]
        await confirmation(expectedCount: 3) { confirmed in
            for await oneResult in result {
                let oneExpected = expected.removeFirst()
                #expect(oneResult == oneExpected)
                confirmed()
            }
        }
    }

    @Test("array: returns the expected array")
    func array() async throws {
        let subject = SimpleAsyncSequence(array: [1, 2, 3])
        let result = subject.map { i in
            let task = Task { i*2 }
            return await task.value
        }
        let expected = [2, 4, 6]
        #expect(try await result.array() == expected)
    }
}
