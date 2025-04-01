import UIKit

/// Protocol describing UIApplication for purposes of background tasks.
@MainActor
public protocol ApplicationType {
    // weirdly, have to specify iOS here because tvOS variant is different; I have no idea why Xcode thinks we would be building for tvOS
    @available(iOS 7.0, *)
    @MainActor func beginBackgroundTask(expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    @available(iOS 7.0, *)
    @MainActor func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    @MainActor func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

/// Extension where UIApplication adopts our protocol.
extension UIApplication: ApplicationType {}
