import UIKit

/// Subclass of UIAlertAction that retains and makes accessible its action handler. We can't subclass
/// UIAlertController but it is not forbidden to subclass UIAlertAction! In this way, we can run an
/// action's handler when testing. Sneaky, eh?
final class AlertAction: UIAlertAction {
    /// The handler passed in at initialization time.
    var handler: ((UIAlertAction) -> Void)?
    
    /// Initialize a UIAlertAction in such a way as to make it testable.
    /// - Parameters:
    ///   - actionTitle: The title of the button representing the action. Note the name of this parameter,
    ///       which differentiates the initializer.
    ///   - style: The action style. May be omitted; the default is `default`.
    ///   - handler: The handler to be run when the button is tapped.
    /// 
    convenience init(actionTitle: String, style: UIAlertAction.Style? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: actionTitle, style: style ?? .default, handler: handler)
        self.handler = handler
    }
}
