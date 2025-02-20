@testable import Dromio
import Foundation

final class MockNetworker: NetworkerType {
    var dataToReturn = [Data()]
    var errorToThrow: (any Error)?
    var methodsCalled = [String]()
    var url: URL?

    func performRequest(url: URL) async throws -> Data {
        self.url = url
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
        return dataToReturn.removeFirst()
    }
}
