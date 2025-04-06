import UIKit

final class PingView: UIView {
    @objc var borderColor: UIColor {
        get {
            UIColor(cgColor: layer.borderColor ?? UIColor.clear.cgColor)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
}
