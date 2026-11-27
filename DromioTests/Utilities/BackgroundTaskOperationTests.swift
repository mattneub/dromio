@testable import Dromio
import Testing
import UIKit

struct BackgroundTaskOperationTests {

    @Test("start: calls application begin background task, calls whatToDo, calls application end background task")
    func start() async throws {
        let application = MockApplication()
        nonisolated(unsafe) var done = false
        nonisolated(unsafe) var cleanupRan = false
        let subject = BackgroundTaskOperation(
            whatToDo: {
                done = true
            },
            cleanup: {
                cleanupRan = true
            },
            application: application
        )
        try await subject.start()
        #expect(done)
        #expect(!cleanupRan)
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: with timeout calls application begin background task, calls cleanup, calls application end background task")
    func startWithTimeout() async throws {
        let application = MockApplication()
        application.timeout = true
        nonisolated(unsafe) var completed = false
        nonisolated(unsafe) var cleanupRan = false
        let task = Task {
            try await Task.sleep(for: .seconds(1))
            completed = true
        }
        let subject = BackgroundTaskOperation(
            whatToDo: {
                try? await task.value
            },
            cleanup: {
                cleanupRan = true
                task.cancel()
            },
            application: application
        )
        try? await subject.start()
        #expect(!completed)
        #expect(cleanupRan)
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: if `whatToDo` throws, calls cleanup, calls application end background task, rethrows")
    func startWithThrow() async throws {
        let application = MockApplication()
        nonisolated(unsafe) var cleanupRan = false
        let subject = BackgroundTaskOperation(
            whatToDo: {
                throw TestError.someActualError
            },
            cleanup: {
                cleanupRan = true
            },
            application: application
        )
        await #expect {
            try await subject.start()
        } throws: { error in
            (error as? TestError) == TestError.someActualError
        }
        #expect(cleanupRan)
        #expect(application.methodsCalled == ["beginBackgroundTask(expirationHandler:)", "endBackgroundTask(_:)"])
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }
}

private enum TestError: Error {
    case someActualError
}
