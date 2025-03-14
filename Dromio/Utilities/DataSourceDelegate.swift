import UIKit

/// Protocol describing a type that can maintain a table view's data source and can function as its delegate.
/// How the actual type does this is an internal implementation detail; the only absolute
/// requirement is that the initializer must set the table view's `dataSource` and `delegate`.
///
@MainActor protocol DataSourceDelegate<ActionType, StateType, T>: NSObjectProtocol, Receiver {
    associatedtype ActionType
    associatedtype StateType

    /// Processor to whom to send any action messages.
    var processor: (any Receiver<ActionType>)? { get set }

    /// Weak reference, purely for testing purposes.
    var tableView: UITableView? { get }

    /// Initializer.
    /// - Parameter tableView: The table view whose `dataSource` and `delegate` we will set.
    init(tableView: UITableView)

    /// Display the given state in the table view (by configuring the data source).
    /// - Parameter state: The state to display.
    func present(_ state: StateType)

    func receive(_ effect: T)
}

@MainActor protocol SearchHandler: UISearchResultsUpdating, UISearchControllerDelegate {}

/// Variety of protocol `DataSourceDelegate` that is also a search controller updater and delegate.
///
@MainActor protocol DataSourceDelegateSearcher<ActionType, StateType, EffectType>: DataSourceDelegate, SearchHandler where ActionType == ActionType {
    associatedtype EffectType where EffectType == T

    func updateSearchResults(for searchController: UISearchController)
}

