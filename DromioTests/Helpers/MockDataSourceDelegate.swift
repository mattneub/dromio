@testable import Dromio
import UIKit

@MainActor
final class MockDataSourceDelegate<StateType, ActionType>: NSObject, DataSourceDelegateSearcher {
    var methodsCalled = [String]()
    var processor: (any Receiver<ActionType>)?
    var state: StateType?
    var tableView: UITableView?

    var datasource: UITableViewDiffableDataSource<String, String>!

    init(tableView: UITableView) {
        methodsCalled.append(#function)
        self.tableView = tableView
    }

    func present(_ state: StateType) {
        methodsCalled.append(#function)
        self.state = state
    }

    func updateSearchResults(for searchController: UISearchController) {
        methodsCalled.append(#function)

    }
}
