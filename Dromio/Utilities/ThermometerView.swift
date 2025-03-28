import UIKit

final class ThermometerView: UIView {
    static var thermometerFillColor = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .light {
            UIColor(red: 1, green: 0.939, blue: 0.5, alpha: 1)
        } else {
            UIColor(red: 0.538, green: 0.273, blue: 0.039, alpha: 1)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
    }

    var progress: Double = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        Self.thermometerFillColor.setFill()
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: progress * rect.width, height: rect.height))
        path.fill()
    }
}
