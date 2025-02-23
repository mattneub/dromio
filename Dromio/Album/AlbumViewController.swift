import UIKit

/// View controller that displays a list of all songs in an album.
final class AlbumViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegate<AlbumAction, AlbumState>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    var processor: (any Receiver<AlbumAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = AlbumDataSourceDelegate(tableView: tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .red
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: AlbumState) {
        dataSourceDelegate?.present(state)
    }

    func receive(_ effect: AlbumEffect) {
        switch effect {
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
    }
}
