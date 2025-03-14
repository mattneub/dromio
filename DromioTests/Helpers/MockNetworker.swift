@testable import Dromio
import Foundation
import Combine

final class MockNetworker: NetworkerType {

    var progress = PassthroughSubject<(id: String, fraction: Double?), Never>()

    var dataToReturn = [Data()]
    var errorToThrow: (any Error)?
    var methodsCalled = [String]()
    var url: URL?
    var urlToReturn = URL(string: "http://example.com")!
    var id: String?
    var fraction: Double?

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

    func progress(id: String, fraction: Double?) {
        methodsCalled.append(#function)
        self.id = id
        self.fraction = fraction
    }

}
