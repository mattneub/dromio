import UIKit

extension UIResponder {
    /// Walk the responder chain looking for the first instance of a given class.
    /// - parameter ofType: The UIResponder subclass to look for an instance of.
    /// - Returns: The instance (typed as an Optional of the desired class) or `nil`.
    func next<T: UIResponder>(ofType: T.Type) -> T? {
        let nextResponder = self.next
        if let responder = nextResponder as? T ?? nextResponder?.next(ofType: T.self) {
            return responder
        } else {
            return nil
        }
    }
}
