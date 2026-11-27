@testable import Dromio
import UIKit

final class MockApplication: @MainActor ApplicationType {
    var methodsCalled = [String]()
    var identifierToReturn: UIBackgroundTaskIdentifier = .init(rawValue: 1)
    var identifierAtEnd: UIBackgroundTaskIdentifier?
    var timeout = false

    func beginBackgroundTask(expirationHandler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
        methodsCalled.append(#function)
        defer {
            if timeout {
                expirationHandler?()
            }
        }
        return identifierToReturn
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        methodsCalled.append(#function)
        identifierAtEnd = identifier
    }
}
