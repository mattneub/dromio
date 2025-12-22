@testable import Dromio
import Testing
import Foundation

struct FileCleanupTrait: TestTrait, SuiteTrait, TestScoping {
    let isRecursive = true

    // see discussion at https://github.com/swiftlang/swift/issues/85161
    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        try await function()
        print("cleanup!")
        let fileManager = FileManager.default
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: URL.cachesDirectory,
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: URL.temporaryDirectory,
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}

extension Trait where Self == FileCleanupTrait {
    static var fileCleanup: Self {
        Self()
    }
}
