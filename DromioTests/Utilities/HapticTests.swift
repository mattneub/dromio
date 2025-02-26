@testable import Dromio
import Testing
import UIKit

@MainActor
struct HapticTests {
    let subject = Haptic()
    let mockGenerator = MockGenerator()

    init() {
        subject.generator = mockGenerator
    }

    @Test("success: calls prepare, notificationOccurred with success")
    func success() {
        subject.success()
        #expect(mockGenerator.methodsCalled[0] == "prepare()")
        #expect(mockGenerator.methodsCalled[1] == "notificationOccurred(_:)")
        #expect(mockGenerator.type == .success)
    }

    @Test("failure: calls notificationOccurred with error")
    func failure() {
        subject.failure()
        #expect(mockGenerator.methodsCalled == ["notificationOccurred(_:)"])
        #expect(mockGenerator.type == .error)
    }
}

@MainActor
final class MockGenerator: GeneratorType {
    var methodsCalled = [String]()
    var type: UINotificationFeedbackGenerator.FeedbackType?

    func prepare() {
        methodsCalled.append(#function)
    }
    
    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        methodsCalled.append(#function)
        self.type = type
    }
}
