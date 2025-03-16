@testable import Dromio
import Testing
import UIKit

@MainActor
struct UIViewTests {
    @Test("subviews(ofType:) returns array of type, recursing or not, including hidden or not")
    func subviewsOfType() {
        let view = UIView()
        view.addSubview(UIButton(type: .system))
        view.addSubview(UILabel())
        let otherView = UIView()
        view.addSubview(otherView)
        otherView.isHidden = true
        otherView.addSubview(UITextView())
        let textView = UITextView()
        view.addSubview(textView)
        textView.isHidden = true
        view.addSubview(UIButton(type: .custom))
        #expect(view.subviews(ofType: UISwitch.self).count == 0)
        #expect(view.subviews(ofType: UILabel.self).count == 1)
        #expect(view.subviews(ofType: UITextView.self).count == 0)
        #expect(view.subviews(ofType: UITextView.self, includeHidden: true).count == 2)
        let buttons = view.subviews(ofType: UIButton.self)
        #expect(buttons.count == 2)
        #expect(buttons[0].buttonType == .system)
        #expect(buttons[1].buttonType == .custom)

        let subview = UIView()
        view.addSubview(subview)
        subview.addSubview(UISwitch())
        #expect(view.subviews(ofType: UISwitch.self).count == 1)
        #expect(view.subviews(ofType: UISwitch.self, recursing: false).count == 0)
    }
}
