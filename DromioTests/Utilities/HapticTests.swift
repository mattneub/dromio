@testable import Dromio
import Testing
import UIKit

struct HapticTests {
    let subject = Haptic()
    let mockNotificationGenerator = MockNotificationGenerator()
    let mockImpactGenerator = MockImpactGenerator()

    init() {
        subject.notificationFeedbackGenerator = mockNotificationGenerator
        subject.impactFeedbackGenerator = mockImpactGenerator
    }

    @Test("success: calls prepare, notificationOccurred with success")
    func success() {
        subject.success()
        #expect(mockNotificationGenerator.methodsCalled[0] == "prepare()")
        #expect(mockNotificationGenerator.methodsCalled[1] == "notificationOccurred(_:)")
        #expect(mockNotificationGenerator.type == .success)
    }

    @Test("failure: calls notificationOccurred with error")
    func failure() {
        subject.failure()
        #expect(mockNotificationGenerator.methodsCalled == ["notificationOccurred(_:)"])
        #expect(mockNotificationGenerator.type == .error)
    }

    @Test("impact: calls impact")
    func impact() {
        subject.impact()
        #expect(mockImpactGenerator.methodsCalled == ["impactOccurred(intensity:)"])
        #expect(mockImpactGenerator.intensity == 1)
    }
}

final class MockNotificationGenerator: NotificationFeedbackGeneratorType {
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

final class MockImpactGenerator: ImpactFeedbackGeneratorType {
    var methodsCalled = [String]()
    var intensity: CGFloat?

    func impactOccurred(intensity: CGFloat) {
        methodsCalled.append(#function)
        self.intensity = intensity
    }
}
