@testable import Dromio

@MainActor
final class MockNetworker: NetworkerType {
    var pingError: Error?
    var methodsCalled = [String]()

    func ping() async throws {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
    }
}
