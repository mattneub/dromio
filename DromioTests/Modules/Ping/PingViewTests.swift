@testable import Dromio
import Testing
import UIKit

@MainActor
struct PingViewTests {
    @Test("Getting background color gets layer background color")
    func getBackgroundColor() {
        let subject = PingView()
        subject.layer.backgroundColor = UIColor.yellow.cgColor
        #expect(subject.backgroundColor == .yellow)
    }

    @Test("Setting background color gets layer background color")
    func setBackgroundColor() {
        let subject = PingView()
        subject.backgroundColor = .yellow
        #expect(subject.layer.backgroundColor == UIColor.yellow.cgColor)
    }
}
