import UIKit

/// Class containing boilerplate for configuring search bar, so we don't keep repeating it.
class SearchConfigurator {
    init() {}

    func configure(viewController: UIViewController, updater: (any SearchHandler)?) {
        let controller = UISearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = false
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = updater
        controller.delegate = updater
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.autocorrectionType = .no
        controller.searchBar.spellCheckingType = .no
        controller.searchBar.inlinePredictionType = .no
        viewController.navigationItem.searchController = controller
        viewController.navigationItem.searchBarPlacementAllowsToolbarIntegration = true
        viewController.navigationItem.preferredSearchBarPlacement = .integratedButton
        let spacer = UIBarButtonItem.flexibleSpace()
        let searchbarPlacer = viewController.navigationItem.searchBarPlacementBarButtonItem
        viewController.toolbarItems = [spacer, searchbarPlacer]
    }
}
