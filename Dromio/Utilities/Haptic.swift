import UIKit

@MainActor
protocol HapticType {
    func success()
}

@MainActor
protocol GeneratorType {
    func prepare()
    func notificationOccurred(_: UINotificationFeedbackGenerator.FeedbackType)
}

extension UINotificationFeedbackGenerator: GeneratorType {}

@MainActor
final class Haptic: HapticType {
    var generator: GeneratorType = UINotificationFeedbackGenerator()

    func success() {
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
