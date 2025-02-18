@testable import Dromio

@MainActor
final class MockNetworker: NetworkerType {
    var valueToReturnFromPing = false
    var methodsCalled = [String]()

    func ping() -> Bool {
        methodsCalled.append(#function)
        return valueToReturnFromPing
    }
}
