import UIKit

final class ThermometerView: UIView {
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
        UIColor.systemYellow.setFill()
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: progress * rect.width, height: rect.height))
        path.fill()
    }
}
