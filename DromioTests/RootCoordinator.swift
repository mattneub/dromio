@testable import Dromio
import Testing
import UIKit

@MainActor
struct RootCoordinatorTests {
    @Test("createInitialInterface: creates the initial interface and module")
    func createInitialInterface() throws {
        let subject = RootCoordinator()
        let window = UIWindow()
        subject.createInitialInterface(window: window)
        let pingProcessor = try #require(subject.pingProcessor as? PingProcessor)
        let rootViewController = try #require(subject.rootViewController as? UINavigationController)
        let pingViewController = try #require(rootViewController.viewControllers.first as? PingViewController)
        #expect(pingViewController.processor === pingProcessor)
        #expect(pingProcessor.presenter === pingViewController)
    }
}
