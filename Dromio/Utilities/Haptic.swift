import UIKit

@MainActor
protocol HapticType {
    func failure()
    func success()
    func impact()
}

@MainActor
protocol NotificationFeedbackGeneratorType {
    func prepare()
    func notificationOccurred(_: UINotificationFeedbackGenerator.FeedbackType)
}

@MainActor
protocol ImpactFeedbackGeneratorType {
    func impactOccurred(intensity: CGFloat)
}

extension UINotificationFeedbackGenerator: NotificationFeedbackGeneratorType {}
extension UIImpactFeedbackGenerator: ImpactFeedbackGeneratorType {}

@MainActor
final class Haptic: HapticType {
    var notificationFeedbackGenerator: NotificationFeedbackGeneratorType = UINotificationFeedbackGenerator()
    var impactFeedbackGenerator: ImpactFeedbackGeneratorType = UIImpactFeedbackGenerator()

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
