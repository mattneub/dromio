import UIKit

/// View controller that displays a list of all albums.
final class AlbumsViewController: UITableViewController, Presenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegate<AlbumsAction, AlbumsState>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    weak var processor: (any Receiver<AlbumsAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = AlbumsDataSourceDelegate(tableView: tableView)
        title = "All Albums"
        do {
            let item = UIBarButtonItem(
                title: nil, image: UIImage(systemName: "list.bullet"), target: self, action: #selector(showPlaylist)
            )
            navigationItem.rightBarButtonItem = item
        }
        do {
            let menu = UIMenu() // real menu will be provided by `present`
            let item = UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"), menu: menu)
            navigationItem.leftBarButtonItem = item
        }
        tableView.estimatedRowHeight = 68
        tableView.sectionIndexColor = .systemRed
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .systemBackground
        Task {
            await processor?.receive(.allAlbums)
        }
    }

    func present(_ state: AlbumsState) {
        title = switch state.listType {
        case .allAlbums: "All Albums"
        case .randomAlbums: "Random Albums"
        }
        navigationItem.leftBarButtonItem?.menu = menu(for: state.listType)
        dataSourceDelegate?.present(state)
    }

    private func menu(for listType: AlbumsState.ListType) -> UIMenu {
        switch listType {
        case .allAlbums:
            UIMenu(title: "", options: [], children: [
                UIAction(title: "Random Albums", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.randomAlbums)
                    }
                }),
                UIAction(title: "Artists", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.artists)
                    }
                }),
            ])
        case .randomAlbums:
            UIMenu(title: "", options: [], children: [
                UIAction(title: "All Albums", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.allAlbums)
                    }
                }),
                UIAction(title: "Artists", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.artists)
                    }
                }),
            ])
        }
    }

    @objc func showPlaylist() {
        Task {
            await processor?.receive(.showPlaylist)
        }
    }
}
