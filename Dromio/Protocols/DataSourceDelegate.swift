import UIKit

/// Protocol describing a type that can maintain a table view's data source and can function as its delegate.
/// How the actual type does this is an internal implementation detail; the only absolute
/// requirement is that the initializer must set the table view's `dataSource` and `delegate`.
///
protocol DataSourceDelegate<ProcessorAction, State, Received>: NSObjectProtocol, ReceiverPresenter {
    associatedtype ProcessorAction

    /// Processor to whom to send any action messages.
    var processor: (any Receiver<ProcessorAction>)? { get set }

    /// Weak reference back to the table view, mostly for testing purposes.
    var tableView: UITableView? { get }

    /// Initializer.
    /// - Parameter tableView: The table view whose `dataSource` and `delegate` we will set.
    init(tableView: UITableView)

    /// Given a piece of string data, returns the corresponding index path.
    /// - Parameter forDatum: The datum.
    /// - Returns: The index path, or nil if there is none.
    /// Assumes that some string is uniquely determinative of the data (e.g. its `id`). This is
    /// true throughout the app, which uses the data `id` as the item identifier type of
    /// the diffable data source, but it is still rather a bold assumption; however, I didn't want
    /// to add yet another generic type.
    func indexPath(forDatum: String) -> IndexPath?
}

/// Extension which allows adopters not to implement `indexPath(forDatum:)`.
extension DataSourceDelegate {
    func indexPath(forDatum: String) -> IndexPath? {
        return nil
    }
}

/// Protocol combining two built-in types: it can update results for a UISearchController and can function as its delegate.
/// 
protocol SearchHandler: UISearchResultsUpdating, UISearchControllerDelegate, Sendable {}

/// Variety of protocol `DataSourceDelegate` that is also a search controller updater and delegate.
///
protocol DataSourceDelegateSearcher<ProcessorAction, State, Received>: DataSourceDelegate, SearchHandler {
    func updateSearchResults(for searchController: UISearchController)
}
