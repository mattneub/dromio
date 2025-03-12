import UIKit

@MainActor
final class MockTableView: UITableView {
    var methodsCalled = [String]()
    var indexPath: IndexPath?

    override func reloadSectionIndexTitles() {
        methodsCalled.append(#function)
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        methodsCalled.append(#function)
        self.indexPath = indexPath
    }
}
