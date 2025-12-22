import UIKit

/// Protocol describing UIApplication for purposes of background tasks, so we can mock it for testing.
public protocol ApplicationType {
    // weirdly, have to specify iOS here because tvOS variant is different; I have no idea why Xcode thinks we would be building for tvOS
    @available(iOS 18.0, *)
    @MainActor func beginBackgroundTask(expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    @MainActor func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

/// Extension where UIApplication adopts our protocol.
extension UIApplication: ApplicationType {}
