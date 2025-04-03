@testable import Dromio
import Testing
import UIKit

@MainActor
struct BackgroundTaskOperationTests {

    @Test("start: calls application begin background task, calls whatToDo, calls application end background task")
    func start() async throws {
        let application = MockApplication()
        try await confirmation(expectedCount: 1) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { confirmed() }, cleanup: { throw TestError.codeShouldNotRun }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.2))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    @Test("start: with timeout calls application begin background task, calls cleanup, calls application end background task")
    func startWithTimeout() async throws {
        let application = MockApplication()
        application.timeout = true
        try await confirmation(expectedCount: 2) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { confirmed() }, cleanup: { confirmed() }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.2))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }

    // TODO: Keep an eye on this test, it has flickered and I don't know why
    @Test("start: if `whatToDo` throws, calls cleanup")
    func startWithThrow() async throws {
        let application = MockApplication()
        application.timeout = true
        try? await confirmation(expectedCount: 1) { confirmed in
            let subject = BackgroundTaskOperation(whatToDo: { throw TestError.codeShouldNotRun }, cleanup: { confirmed() }, application: application)
            try await subject.start()
            try? await Task.sleep(for: .seconds(0.2))
        }
        #expect(application.methodsCalled.contains("beginBackgroundTask(expirationHandler:)"))
        #expect(application.methodsCalled.contains("endBackgroundTask(_:)"))
        #expect(application.identifierToReturn == application.identifierAtEnd)
    }
}

private enum TestError: Error {
    case codeShouldNotRun
}
