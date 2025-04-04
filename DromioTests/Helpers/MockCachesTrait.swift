@testable import Dromio
import Testing

@MainActor
struct MockCachesTrait: TestTrait, TestScoping {
    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        caches = MockCaches()
        try await function()
        caches = Caches()
    }
}

extension Trait where Self == MockCachesTrait {
    static var mockCaches: Self {
        Self()
    }
}
