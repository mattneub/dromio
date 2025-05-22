@testable import Dromio
import Testing
import UIKit
import SwiftUI

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

    @Test("animate(withDuration:): calls base animate(withDuration:)")
    func animate() async {
        let view = MockUIView()
        await MockUIView.animate(withDuration: 0.1, delay: 0.2, options: .curveEaseOut, animations: { view.backgroundColor = .red })
        #expect(MockUIView.duration == 0.1)
        #expect(MockUIView.delay == 0.2)
        #expect(MockUIView.options == .curveEaseOut)
        #expect(view.backgroundColor == .red)
        #expect(MockUIView.completion != nil) // because we inject `continuation(resume:)`
    }
}

final class MockUIView: UIView {
    static var duration: TimeInterval = 0
    static var delay: TimeInterval = 0
    static var options: UIView.AnimationOptions = []
    static var completion: ((Bool) -> Void)? = nil
    static var animation: Animation?
    override static func animate(withDuration duration: TimeInterval, delay: TimeInterval, options: UIView.AnimationOptions = [], animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        self.duration = duration
        self.delay = delay
        self.options = options
        self.completion = completion
        animations()
        completion?(true)
    }
    // unfortunately I can't do that for the SwiftUI version because it is declared in an extension :(
}
