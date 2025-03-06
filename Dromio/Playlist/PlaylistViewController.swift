import UIKit

/// View controller that displays a list of all songs in an album.
final class PlaylistViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegate<PlaylistAction, PlaylistState>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    var processor: (any Receiver<PlaylistAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = PlaylistDataSourceDelegate(tableView: tableView)
        tableView.estimatedRowHeight = 90
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .systemBackground
        let rightBarButtonItem = UIBarButtonItem(title: "Clear", image: nil, target: self, action: #selector(doClear))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: PlaylistState) {
        dataSourceDelegate?.present(state)
    }

    func receive(_ effect: PlaylistEffect) {
        switch effect {
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
    }

    @objc func doClear() {
        Task {
            await processor?.receive(.clear)
        }
    }
}
