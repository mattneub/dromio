import UIKit

/// Protocol embodying the public interface for the root coordinator.
@MainActor
protocol RootCoordinatorType: AnyObject {
    // Processors are rooted here. They are all expressed as protocols, for testability.

    var pingProcessor: (any Processor<PingAction, PingState>)? { get }

    // The root coordinator also needs a reference to the true root view controller.

    var rootViewController: UIViewController? { get set }

    /// Create the entire initial interface and modules, rooted in the given window.
    /// - Parameter window: The window
    func createInitialInterface(window: UIWindow)

}

/// Class of single instance responsible for all view controller manipulation.
@MainActor
final class RootCoordinator: RootCoordinatorType {

    var pingProcessor: (any Processor<PingAction, PingState>)?

    weak var rootViewController: UIViewController?

    func createInitialInterface(window: UIWindow) {
        let pingController = PingViewController(nibName: "Ping", bundle: nil)
        let navigationController = UINavigationController(rootViewController: pingController)
        window.rootViewController = navigationController
        self.rootViewController = window.rootViewController
        let pingProcessor = PingProcessor()
        self.pingProcessor = pingProcessor
        pingProcessor.presenter = pingController
        pingController.processor = pingProcessor
    }
}

