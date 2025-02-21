import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Root coordinator for the app is anchored here.
    lazy var rootCoordinator: any RootCoordinatorType = RootCoordinator()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }

        // do not bootstrap any interface if we are unit testing
        if NSClassFromString("XCTest") != nil {
            return
        }

        bootstrap(scene: scene)
    }

    /// Make the window, tell the coordinator to build the initial interface, and show the window.
    /// - Parameter scene: The window scene to use for the window.
    func bootstrap(scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        self.window = window
        rootCoordinator.createInitialInterface(window: window)
        window.makeKeyAndVisible()
    }
}

