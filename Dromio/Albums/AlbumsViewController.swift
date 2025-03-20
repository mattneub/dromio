import UIKit

/// View controller that displays a list of all albums.
final class AlbumsViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegateSearcher<AlbumsAction, AlbumsState, Void>)?

    /// Searcher that handles our search controller management. It's a var for testing purposes.
    var searcher = Searcher()

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    weak var processor: (any Receiver<AlbumsAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    let activity: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .large)
        activity.color = .label
        activity.translatesAutoresizingMaskIntoConstraints = false
        return activity
    }()

    lazy var tableViewBackground: UIView = {
        let view = UIView()
        view.addSubview(activity)
        view.centerYAnchor.constraint(equalTo: activity.centerYAnchor).isActive = true
        view.centerXAnchor.constraint(equalTo: activity.centerXAnchor).isActive = true
        return view
    }()

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
        tableView.estimatedRowHeight = 68
        tableView.sectionIndexColor = .systemRed
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .background
        tableView.backgroundView = tableViewBackground
        activity.startAnimating()
        Task {
            try? await unlessTesting {
                // cosmetic, looks better if we wait a moment
                try? await Task.sleep(for: .seconds(0.4))
            }
            await processor?.receive(.initialData)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            await processor?.receive(.viewDidAppear)
        }
    }

    func receive(_ effect: AlbumsEffect) async {
        switch effect {
        case .setUpSearcher:
            await searcher.setUpSearcher(navigationItem: navigationItem, updater: dataSourceDelegate)
        case .tearDownSearcher:
            await searcher.tearDownSearcher(navigationItem: navigationItem, tableView: tableView)
        }
    }

    func present(_ state: AlbumsState) {
        activity.stopAnimating()
        title = switch state.listType {
        case .allAlbums: 
            "All Albums"
        case .randomAlbums: 
            "Random Albums"
        case .albumsForArtist:
            nil
        }

        navigationItem.leftBarButtonItem = switch state.listType {
        case .allAlbums, .randomAlbums:
            UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"), menu: UIMenu())
        case .albumsForArtist:
            nil
        }

        Task {
            await searcher.setUpSearcher(navigationItem: navigationItem, updater: dataSourceDelegate)
        }

        navigationItem.leftBarButtonItem?.menu = menu(for: state.listType)
        dataSourceDelegate?.present(state)
    }
    
    /// Private subroutine of `present` that generates the left bar button item menu, depending
    /// on the presented state's list type.
    /// - Parameter listType: The list type.
    /// - Returns: The menu.
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
                UIAction(title: "Server", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.server)
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
                UIAction(title: "Server", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.server)
                    }
                }),
            ])
        case .albumsForArtist:
            UIMenu()
        }
    }

    @objc func showPlaylist() {
        Task {
            await processor?.receive(.showPlaylist)
        }
    }

    deinit {
        logger.log("farewell from albums")
    }
}
