@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {
    var pingProcessor: (any Dromio.Processor<Dromio.PingAction, Dromio.PingState>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()

    func createInitialInterface(window: UIWindow) {
        methodsCalled.append(#function)
    }

}
