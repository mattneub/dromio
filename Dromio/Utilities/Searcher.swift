import UIKit

/// Small class that maintains a search controller, to get the duplication out of the searchable
/// view controllers. This stuff is rather fiddly so, having settled on a formulation that
/// works, it's good to get it in one place.
///
@MainActor
class Searcher {
    /// The search controller.
    var searchController: UISearchController?

    // Our code masks a bizarre race condition because of the Task.sleep calls; use these flags
    // to prevent setting up in the middle of tearing down or vice versa.
    // (Surely there's a better way to deal with this...?)
    var settingUp = false
    var tearingDown = false

    /// Create and configure the search controller.
    /// - Parameters:
    ///   - navigationItem: Navigation item to add the search bar to.
    ///   - updater: Search results updater and search controller delegate.
    ///
    func setUpSearcher(navigationItem: UINavigationItem, updater: (any SearchHandler)?) async {
        if searchController == nil {
            guard let updater else { return }
            guard !tearingDown else {
                return
            }
            settingUp = true
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
            settingUp = false
        }
    }

    /// Destroy the search controller and take away the search bar, in good order..
    /// - Parameters:
    ///   - navigationItem: Navigation item to add the search bar to.
    ///   - updater: Search results updater and search controller delegate.
    ///
    func tearDownSearcher(navigationItem: UINavigationItem, tableView: UITableView) async {
        if let controller = searchController {
            guard !settingUp else {
                return
            }
            tearingDown = true
            logger.log("tearDownSearcher")
            // tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
            controller.isActive = false
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.1))
            }
            navigationItem.searchController = nil
            searchController = nil
            tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
            tearingDown = false
        }
    }
}
