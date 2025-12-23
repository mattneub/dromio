import UIKit

/// Protocol describing UIApplication for purposes of background tasks, so we can mock it for testing.
public protocol ApplicationType {
    #if DEBUG
    nonisolated func beginBackgroundTask(expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    #else
    nonisolated func beginBackgroundTask(expirationHandler handler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    #endif
    nonisolated func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

/// Extension where UIApplication adopts our protocol.
extension UIApplication: ApplicationType {}
