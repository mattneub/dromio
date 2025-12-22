@testable import Dromio
import Testing
import UIKit

struct SearcherConfiguratorTests {
    let subject = SearchConfigurator()

    @Test("configure: behaves as expected")
    func configure() async throws {
        let viewController = UIViewController()
        let handler = MockSearchHandler()
        subject.configure(viewController: viewController, updater: handler)
        let controller = try #require(viewController.navigationItem.searchController)
        #expect(controller.hidesNavigationBarDuringPresentation == false)
        #expect(controller.obscuresBackgroundDuringPresentation == false)
        #expect(controller.searchResultsUpdater === handler)
        #expect(controller.delegate === handler)
        #expect(controller.searchBar.autocapitalizationType == .none)
        #expect(controller.searchBar.autocorrectionType == .no)
        #expect(controller.searchBar.spellCheckingType == .no)
        #expect(controller.searchBar.inlinePredictionType == .no)
        #expect(viewController.navigationItem.searchBarPlacementAllowsToolbarIntegration == true)
        #expect(viewController.navigationItem.preferredSearchBarPlacement == .integratedButton)
        let toolbarItems = try #require(viewController.toolbarItems)
        #expect(toolbarItems.count == 2)
        #expect(toolbarItems[0] == UIBarButtonItem.flexibleSpace())
        #expect(toolbarItems[1] == viewController.navigationItem.searchBarPlacementBarButtonItem)
    }
}

final class MockSearchHandler: NSObject, SearchHandler {
    func updateSearchResults(for searchController: UISearchController) {
    }
}
