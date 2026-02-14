import UIKit

/// Protocol expressing the public face of our Haptic class.
protocol HapticType {
    func failure()
    func success()
    func impact()
}

/// Class that simplifies our interaction with the built-in feedback generators.
final class Haptic: HapticType {
    var notificationFeedbackGenerator: any NotificationFeedbackGeneratorType = UINotificationFeedbackGenerator()
    var impactFeedbackGenerator: any ImpactFeedbackGeneratorType = UIImpactFeedbackGenerator()

    func failure() {
        notificationFeedbackGenerator.notificationOccurred(.error)
    }

    func success() {
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }

    func impact() {
        impactFeedbackGenerator.impactOccurred(intensity: 1.0)
    }
}
