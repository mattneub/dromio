@testable import Dromio
import UIKit

@MainActor
final class MockDataSourceDelegate<StateType, ActionType, EffectType>: NSObject, DataSourceDelegateSearcher {
    var methodsCalled = [String]()
    var thingsReceived = [EffectType]()
    var processor: (any Receiver<ActionType>)?
    var state: StateType?
    var tableView: UITableView?
    var datum: String?
    var indexPath: IndexPath?

    var datasource: UITableViewDiffableDataSource<String, String>!

    init(tableView: UITableView) {
        methodsCalled.append(#function)
        self.tableView = tableView
    }

    func receive(_ effect: EffectType) {
        methodsCalled.append(#function)
        thingsReceived.append(effect)
    }

    func present(_ state: StateType) {
        methodsCalled.append(#function)
        self.state = state
    }

    func indexPath(forDatum datum: String) -> IndexPath? {
        methodsCalled.append(#function)
        self.datum = datum
        return self.indexPath
    }

    func updateSearchResults(for searchController: UISearchController) {
        methodsCalled.append(#function)
    }
}
