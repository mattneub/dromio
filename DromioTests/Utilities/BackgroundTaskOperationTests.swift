@testable import Dromio
import Testing
import UIKit

@MainActor
struct BackgroundTaskOperationTests {
    let application = MockApplication()

    @Test("start: calls application begin background task, calls whatToDo, calls application end background task")
    func start() async throws {
        try await confirmation(expectedCount: 1) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { confirmed() }, cleanup: { throw TestError.codeShouldNotRun }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.1))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: with timeout calls application begin background task, calls cleanup, calls application end background task")
    func startWithTimeout() async throws {
        application.timeout = true
        try await confirmation(expectedCount: 2) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { confirmed() }, cleanup: { confirmed() }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.1))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: if `whatToDo` throws, calls cleanup")
    func startWithThrow() async throws {
        application.timeout = true
        try? await confirmation(expectedCount: 1) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { throw TestError.codeShouldNotRun }, cleanup: { confirmed() }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.1))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }
}

private enum TestError: Error {
    case codeShouldNotRun
}
