import UIKit

/// Protocol that wraps UINotificationFeedbackGenerator, so we can mock it for testing.
protocol NotificationFeedbackGeneratorType {
    func prepare()
    func notificationOccurred(_: UINotificationFeedbackGenerator.FeedbackType)
}

/// Protocol that wraps UIImpactFeedbackGenerator, so we can mock it for testing.
protocol ImpactFeedbackGeneratorType {
    func impactOccurred(intensity: CGFloat)
}

extension UINotificationFeedbackGenerator: NotificationFeedbackGeneratorType {}
extension UIImpactFeedbackGenerator: ImpactFeedbackGeneratorType {}

