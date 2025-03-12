@testable import Dromio
import Testing
import UIKit

@MainActor
struct SearcherTests {
    let subject = Searcher()

    @Test("setUpSearcher: behaves as expected")
    func setUpSearcher() async throws {
        #expect(subject.searchController == nil)
        let navigationItem = UINavigationItem()
        let handler = MockSearchHandler()
        await subject.setUpSearcher(navigationItem: navigationItem, updater: handler)
        let controller = try #require(subject.searchController)
        #expect(controller.hidesNavigationBarDuringPresentation == false)
        #expect(controller.obscuresBackgroundDuringPresentation == false)
        #expect(controller.searchResultsUpdater === handler)
        #expect(controller.delegate === handler)
        #expect(navigationItem.searchController == controller)
        #expect(controller.searchBar.autocapitalizationType == .none)
        #expect(controller.searchBar.autocorrectionType == .no)
        #expect(controller.searchBar.spellCheckingType == .no)
        #expect(controller.searchBar.inlinePredictionType == .no)
    }

    @Test("tearDownSearcher: behaves as expected")
    func tearDownSearcher() async throws {
        let tableView = MockTableView()
        let navigationItem = UINavigationItem()
        let handler = MockSearchHandler()
        await subject.setUpSearcher(navigationItem: navigationItem, updater: handler)
        let controller = try #require(subject.searchController)
        // that was prep, this is the test
        await subject.tearDownSearcher(navigationItem: navigationItem, tableView: tableView)
        #expect(controller.isActive == false)
        #expect(navigationItem.searchController == nil)
        #expect(subject.searchController == nil)
        #expect(tableView.methodsCalled == ["scrollToRow(at:at:animated:)"])
        #expect(tableView.indexPath == .init(row: 0, section: 0))
    }
}

final class MockSearchHandler: NSObject, SearchHandler {
    func updateSearchResults(for searchController: UISearchController) {
    }
}
