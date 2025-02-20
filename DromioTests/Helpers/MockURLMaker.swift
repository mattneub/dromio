@testable import Dromio
import Foundation

@MainActor
final class MockURLMaker: URLMakerType {
    var action: String?
    var additional: KeyValuePairs<String, String>?
    var currentServerInfo: ServerInfo?
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?
    var urlToReturn: URL?

    func urlFor(action: String, additional: KeyValuePairs<String, String>?) throws -> URL {
        self.action = action
        self.additional = additional
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
        return urlToReturn ?? URL(string: "https://www.example.com")!
    }
}
