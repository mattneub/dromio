@testable import Dromio
import Testing
import UIKit
import WaitWhile

struct SearcherConfiguratorTests {
    let subject = SearchConfigurator()

    @Test("configure: behaves as expected")
    func configure() async throws {
        let viewController = UIViewController()
        let _ = makeWindow(viewController: viewController)
        let handler = MockSearchHandler()
        subject.configure(viewController: viewController, updater: handler)
        await #while(viewController.navigationItem.searchController == nil)
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

    @Test("configure: behaves as expected on iPad")
    func configurePad() async throws {
        let viewController = UIViewController()
        let window = makeWindow(viewController: viewController)
        window.traitOverrides.userInterfaceIdiom = .pad
        await #while(viewController.traitCollection.userInterfaceIdiom != .pad)
        let handler = MockSearchHandler()
        subject.configure(viewController: viewController, updater: handler)
        await #while(viewController.navigationItem.searchController == nil)
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
        #expect(viewController.navigationItem.preferredSearchBarPlacement == .stacked) // *
        #expect(viewController.navigationItem.hidesSearchBarWhenScrolling == true) // *
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
