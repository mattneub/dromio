import UIKit

/// View controller that displays a list of all albums.
final class AlbumsViewController: UITableViewController, Presenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegate<AlbumsAction, AlbumsState>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    var processor: (any Receiver<AlbumsAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = AlbumsDataSourceDelegate(tableView: tableView)
        title = "Albums"
        let item = UIBarButtonItem(title: nil, image: UIImage(systemName: "list.bullet"), target: self, action: #selector(showPlaylist))
        navigationItem.rightBarButtonItem = item
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .systemBackground
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: AlbumsState) {
        dataSourceDelegate?.present(state)
    }

    @objc func showPlaylist() {
        Task {
            await processor?.receive(.showPlaylist)
        }
    }
}
