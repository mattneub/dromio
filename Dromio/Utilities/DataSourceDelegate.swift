import UIKit

/// Protocol describing a type that can maintain a table view's data source and can function as its delegate.
/// How the actual type does this is an internal implementation detail; the only absolute
/// requirement is that the initializer must set the table view's `dataSource` and `delegate`.
///
@MainActor protocol DataSourceDelegate<ActionType, StateType>: NSObjectProtocol {
    associatedtype ActionType
    associatedtype StateType

    /// Processor to whom to send any action messages.
    var processor: (any Receiver<ActionType>)? { get set }

    /// Initializer.
    /// - Parameter tableView: The table view whose `dataSource` and `delegate` we will set.
    init(tableView: UITableView)

    /// Display the given state in the table view (by configuring the data source).
    /// - Parameter state: The state to display.
    func present(_ state: StateType)
}

