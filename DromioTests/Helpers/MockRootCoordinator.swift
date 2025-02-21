@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {
    var albumsProcessor: (any Dromio.Processor<Dromio.AlbumsAction, Dromio.AlbumsState>)?

    var pingProcessor: (any Dromio.Processor<Dromio.PingAction, Dromio.PingState>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()

    func createInitialInterface(window: UIWindow) {
        methodsCalled.append(#function)
    }

    func showAlbums() {
        methodsCalled.append(#function)
    }
}
