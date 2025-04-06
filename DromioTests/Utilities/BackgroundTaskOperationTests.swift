@testable import Dromio
import Testing
import UIKit

@MainActor
struct BackgroundTaskOperationTests {

    @Test("start: calls application begin background task, calls whatToDo, calls application end background task")
    func start() async throws {
        let application = MockApplication()
        nonisolated(unsafe) var done = false
        let subject = BackgroundTaskOperation(
            whatToDo: {
                done = true
            },
            cleanup: {
                throw TestError.codeShouldNotRun
            },
            application: application
        )
        try await subject.start()
        #expect(done)
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: with timeout calls application begin background task, calls cleanup, calls application end background task")
    func startWithTimeout() async throws {
        let application = MockApplication()
        application.timeout = true
        nonisolated(unsafe) var done = false
        let task = Task {
            try await Task.sleep(for: .seconds(1))
        }
        let subject = BackgroundTaskOperation(
            whatToDo: {
                try? await task.value
            },
            cleanup: {
                done = true
                task.cancel()
            },
            application: application
        )
        try await subject.start()
        #expect(done)
        // extra call to `endBackgroundTask`, because in the test we cannot prevent the `whatToDo`
        // path from completing normally
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: if `whatToDo` throws, calls cleanup")
    func startWithThrow() async throws {
        let application = MockApplication()
        nonisolated(unsafe) var done = false
        let subject = BackgroundTaskOperation(
            whatToDo: {
                throw TestError.someActualError
            },
            cleanup: {
                done = true
            },
            application: application
        )
        await #expect {
            try await subject.start()
        } throws: { error in
            (error as? TestError) == TestError.someActualError
        }
        #expect(done)
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }
}

private enum TestError: Error {
    case codeShouldNotRun
    case someActualError
}
