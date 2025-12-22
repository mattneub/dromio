@testable import Dromio
import Testing

struct MockCacheTrait: TestTrait, TestScoping {

    @MainActor
    func setCache() {
        services.cache = MockCache()
    }

    @MainActor
    func resetCache() {
        services.cache = Cache()
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        await setCache()
        try await function()
        await resetCache()
    }
}

extension Trait where Self == MockCacheTrait {
    static var mockCache: Self {
        Self()
    }
}
