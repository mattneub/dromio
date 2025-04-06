import UIKit

/// Class for the view surrounding the text and buttons, so that we can set the border color in the xib.
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
