@testable import Dromio
import Testing

struct MockBackgroundTaskOperationMakerTrait: TestTrait, TestScoping {
    @MainActor
    func setOperationMaker() {
        let mockBackgroundTaskOperationMaker = MockBackgroundTaskOperationMaker()
        services.backgroundTaskOperationMaker = mockBackgroundTaskOperationMaker
    }

    @MainActor
    func resetOperationMaker() {
        services.backgroundTaskOperationMaker = BackgroundTaskOperationMaker()
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        await setOperationMaker()
        try await function()
        await resetOperationMaker()
    }
}

extension Trait where Self == MockBackgroundTaskOperationMakerTrait {
    static var mockBackgroundTask: Self {
        Self()
    }
}
