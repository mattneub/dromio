@testable import Dromio
import Foundation

@MainActor
final class MockURLMaker: URLMakerType {
    var action: String?
    var additional: [URLQueryItem]?
    var currentServerInfo: ServerInfo?
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?
    var folderRestrictable: Bool = false
    var urlToReturn: URL?

    func urlFor(
        action: String,
        additional: [URLQueryItem]?,
        folderRestrictable: Bool
    ) throws -> URL {
        self.action = action
        self.additional = additional
        self.folderRestrictable = folderRestrictable
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
        return urlToReturn ?? URL(string: "https://www.example.com")!
    }
}
