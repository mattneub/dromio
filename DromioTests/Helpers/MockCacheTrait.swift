@testable import Dromio
import Testing

@MainActor
struct MockCacheTrait: TestTrait, TestScoping {
    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        services.cache = MockCache()
        try await function()
        services.cache = Cache()
    }
}

extension Trait where Self == MockCacheTrait {
    static var mockCache: Self {
        Self()
    }
}
