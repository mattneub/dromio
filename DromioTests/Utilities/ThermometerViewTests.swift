@testable import Dromio
import Testing
import SnapshotTesting
import UIKit

@MainActor
struct ThermometerViewTests {
    let subject = ThermometerView(frame: CGRect(origin: .zero, size: .init(width: 100, height: 100)))

    @Test("View looks right with progress 1")
    func progress1() {
        subject.progress = 1
        assertSnapshot(of: subject, as: .image)
    }

    @Test("View looks right with progress 0.5")
    func progress05() {
        subject.progress = 0.5
        assertSnapshot(of: subject, as: .image)
    }

    @Test("View looks right with progress 0")
    func progress0() {
        subject.progress = 0
        assertSnapshot(of: subject, as: .image)
    }
}
