@testable import Dromio
import Foundation

final class MockNetworker: NetworkerType {
    var dataToReturn = [Data()]
    var errorToThrow: (any Error)?
    var methodsCalled = [String]()
    var url: URL?
    var urlToReturn = URL(string: "http://example.com")!

    func performRequest(url: URL) async throws -> Data {
        self.url = url
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
        return dataToReturn.removeFirst()
    }

    func performDownloadRequest(url: URL) async throws -> URL {
        self.url = url
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
        return urlToReturn
    }
}
