@testable import Dromio
import UIKit

final class MockSearcher: Searcher {
    var navigationItem: UINavigationItem?
    var tableView: UITableView?
    var updater: (any SearchHandler)?
    var methodsCalled = [String]()

    override func setUpSearcher(navigationItem: UINavigationItem, tableView: UITableView, updater: (any SearchHandler)?) async {
        methodsCalled.append(#function)
        self.navigationItem = navigationItem
        self.updater = updater
    }

    override func tearDownSearcher(navigationItem: UINavigationItem, tableView: UITableView, updater: (any SearchHandler)? = nil) async {
        methodsCalled.append(#function)
        self.navigationItem = navigationItem
        self.tableView = tableView
    }

}
