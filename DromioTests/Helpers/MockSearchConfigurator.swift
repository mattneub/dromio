@testable import Dromio
import UIKit

final class MockSearchConfigurator: SearchConfigurator {
    var viewController: UIViewController?
    var updater: (any SearchHandler)?
    var methodsCalled = [String]()

    override func configure(viewController: UIViewController, updater: (any SearchHandler)?) {
        methodsCalled.append(#function)
        self.viewController = viewController
        self.updater = updater
    }
}
