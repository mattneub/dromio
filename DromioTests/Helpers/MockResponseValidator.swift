@testable import Dromio
import Foundation

@MainActor
final class MockResponseValidator: ResponseValidatorType {
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?

    func validateResponse<T: InnerResponse>(_ jsonResponse: SubsonicResponse<T>) async throws {
        methodsCalled.append(#function)
        if let errorToThrow {
            throw errorToThrow
        }
    }
}
