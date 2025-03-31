@testable import Dromio
import Testing

@MainActor
struct MockBackgroundTaskOperationMakerTrait: TestTrait, TestScoping {
    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let mockBackgroundTaskOperationMaker = MockBackgroundTaskOperationMaker()
        services.backgroundTaskOperationMaker = mockBackgroundTaskOperationMaker
        try await function()
        services.backgroundTaskOperationMaker = BackgroundTaskOperationMaker()
    }
}

extension Trait where Self == MockBackgroundTaskOperationMakerTrait {
    static var mockBackgroundTask: Self {
        Self()
    }
}
