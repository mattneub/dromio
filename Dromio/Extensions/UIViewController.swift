import UIKit

extension UIViewController {
    /// Public property that walks the presentation chain to find the deepest presented view controller.
    /// If there is no presentation chain, the answer is the view controller we started with.
    /// This works nicely with our view controller architecture which is a chain of presentations.
    var ultimatePresented: UIViewController {
        if let presented = presentedViewController {
            return presented.ultimatePresented
        } else {
            return self
        }
    }
}
