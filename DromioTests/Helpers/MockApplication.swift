@testable import Dromio
import UIKit

@MainActor
final class MockApplication: ApplicationType {
    var methodsCalled = [String]()
    var identifierToReturn: UIBackgroundTaskIdentifier = .init(rawValue: 1)
    var identifierAtEnd: UIBackgroundTaskIdentifier?
    var timeout = false

    func beginBackgroundTask(expirationHandler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
        methodsCalled.append(#function)
        if timeout {
            Task {
                expirationHandler?()
            }
        }
        return identifierToReturn
    }

    func beginBackgroundTask(withName taskName: String?, expirationHandler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
        methodsCalled.append(#function)
        if timeout {
            Task {
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
