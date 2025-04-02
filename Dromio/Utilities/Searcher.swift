import UIKit

/// Small class that maintains a search controller, to get the duplication out of the searchable
/// view controllers. This stuff is rather fiddly so, having settled on a formulation that
/// works, it's good to get it in one place.
///
@MainActor
class Searcher {
    /// The search controller.
    var searchController: UISearchController?

    // Our code masks a bizarre race condition because of the Task.sleep calls; use buffer and flag
    // to prevent setting up in the middle of tearing down or vice versa.
    // (Surely there's a better way to deal with this...?)
    var buffer = [(UINavigationItem, UITableView, (any SearchHandler)?) async -> ()]()
    var busy = false

    /// Create and configure the search controller.
    /// - Parameters:
    ///   - navigationItem: Navigation item to add the search bar to.
    ///   - updater: Search results updater and search controller delegate.
    ///
    func setUpSearcher(navigationItem: UINavigationItem, tableView: UITableView, updater: (any SearchHandler)?) async {
        if searchController == nil, let updater {
            guard !busy else {
                buffer.append(setUpSearcher)
                return
            }
            busy = true
            do { // actual work
                logger.log("setUpSearcher")
                let controller = UISearchController(searchResultsController: nil)
                self.searchController = controller
                controller.hidesNavigationBarDuringPresentation = false
                controller.obscuresBackgroundDuringPresentation = false
                controller.searchResultsUpdater = updater
                controller.delegate = updater
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.6))
                }
                navigationItem.searchController = controller
                controller.searchBar.autocapitalizationType = .none
                controller.searchBar.autocorrectionType = .no
                controller.searchBar.spellCheckingType = .no
                controller.searchBar.inlinePredictionType = .no
                logger.log("finished setUpSearcher")
            }
            if !buffer.isEmpty {
                let nextTask = buffer.removeFirst()
                busy = false
                await nextTask(navigationItem, tableView, updater)
            } else {
                busy = false
            }
        }
    }

    /// Destroy the search controller and take away the search bar, in good order..
    /// - Parameters:
    ///   - navigationItem: Navigation item to add the search bar to.
    ///   - updater: Search results updater and search controller delegate.
    ///
    func tearDownSearcher(navigationItem: UINavigationItem, tableView: UITableView, updater: (any SearchHandler)? = nil) async {
        if let controller = searchController {
            guard !busy else {
                buffer.append(tearDownSearcher)
                return
            }
            busy = true
            do { // actual work
                logger.log("tearDownSearcher")
                controller.isActive = false
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.1))
                }
                navigationItem.searchController = nil
                searchController = nil
                logger.log("finished tearDownSearcher")
            }
            if !buffer.isEmpty {
                let nextTask = buffer.removeFirst()
                busy = false
                await nextTask(navigationItem, tableView, nil)
            } else {
                busy = false
            }
        }
    }
}
