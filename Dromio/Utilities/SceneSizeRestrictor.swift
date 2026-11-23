import UIKit

/// Protocol that expresses the public fact of our SceneSizeRestrictor, so we can mock it
/// for test.
protocol SceneSizeRestrictorType {
    func restrict(scene: UIWindowScene, minimumSize: CGSize?, maximumSize: CGSize?)
}

/// Object that tries to restrict the size of the scene.
final class SceneSizeRestrictor: SceneSizeRestrictorType {
    /// Tell the given scene to restrict its minimum and/or maximum sizes to the given sizes.
    /// - Parameters:
    ///   - scene: The window scene.
    ///   - minimumSize: The optional minimum size.
    ///   - maximumSize: The optional maximum size.
    ///
    /// This is useful only on iPad, but it does no harm on iPhone (though nothing will happen).
    /// Moreover, even on iPad you cannot _read_ the resulting size restrictions,
    /// so this file can't be tested. But it does matter!
    func restrict(scene: UIWindowScene, minimumSize: CGSize?, maximumSize: CGSize?) {
        if let minimumSize {
            scene.sizeRestrictions?.minimumSize = minimumSize
        }
        if let maximumSize {
            scene.sizeRestrictions?.maximumSize = maximumSize
        }
    }
}
