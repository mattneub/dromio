import UIKit

extension UIViewController {
    /// Public property that walks the presentation chain to find the deepest presented view controller.
    /// This works nicely with our view controller architecture which is a chain of presentations.
    var ultimatePresented: UIViewController? {
        ultimatePresented()
    }

    /// Private helper of the preceding; it uses a "scratchpad" value to keep track of whether
    /// we have dived one level or more, as this affects the answer.
    private func ultimatePresented(_ depth: Int = 0) -> UIViewController? {
        if let presented = presentedViewController {
            return presented.ultimatePresented(depth + 1) // dive
        } else {
            if presentingViewController != nil {
                if depth > 0 {
                    return self // this is it
                } else {
                    return nil // the v.c. you start with cannot be its own `ultimatePresented`
                }
            } else {
                return nil // neither presented nor presenting, just stop
            }
        }
    }
}
