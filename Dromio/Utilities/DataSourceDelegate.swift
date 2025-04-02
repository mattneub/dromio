import UIKit

/// Protocol describing a type that can maintain a table view's data source and can function as its delegate.
/// How the actual type does this is an internal implementation detail; the only absolute
/// requirement is that the initializer must set the table view's `dataSource` and `delegate`.
///
@MainActor protocol DataSourceDelegate<ProcessorAction, State, Received>: NSObjectProtocol, AsyncReceiverPresenter {
    associatedtype ProcessorAction

    /// Processor to whom to send any action messages.
    var processor: (any Receiver<ProcessorAction>)? { get set }

    /// Weak reference, purely for testing purposes.
    var tableView: UITableView? { get }

    /// Initializer.
    /// - Parameter tableView: The table view whose `dataSource` and `delegate` we will set.
    init(tableView: UITableView)
}

@MainActor protocol SearchHandler: UISearchResultsUpdating, UISearchControllerDelegate, Sendable {}

/// Variety of protocol `DataSourceDelegate` that is also a search controller updater and delegate.
///
@MainActor protocol DataSourceDelegateSearcher<ProcessorAction, State, Received>: DataSourceDelegate, SearchHandler {
    func updateSearchResults(for searchController: UISearchController)
}
