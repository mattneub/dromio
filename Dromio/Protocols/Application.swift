import UIKit

/// Protocol describing UIApplication for purposes of background tasks, so we can mock it for testing.
public protocol ApplicationType {
    nonisolated func beginBackgroundTask(expirationHandler handler: (@MainActor () -> Void)?) -> UIBackgroundTaskIdentifier
    nonisolated func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

/// Extension where UIApplication adopts our protocol.
extension UIApplication: ApplicationType {}
