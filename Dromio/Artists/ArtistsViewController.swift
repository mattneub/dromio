import UIKit

/// View controller that displays a list of all artists.
final class ArtistsViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegateSearcher<ArtistsAction, ArtistsState, Void>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    weak var processor: (any Receiver<ArtistsAction>)? {
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

    /// Object that handles and configures our search controller; it's a var for testing purposes.
    var searcher = Searcher()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = ArtistsDataSourceDelegate(tableView: tableView)
        title = "Artists"
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
        tableView.estimatedRowHeight = 40
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
            await processor?.receive(.allArtists)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            await processor?.receive(.viewDidAppear)
        }
    }

    func receive(_ effect: ArtistsEffect) async {
        switch effect {
        case .setUpSearcher:
            await searcher.setUpSearcher(navigationItem: navigationItem, updater: dataSourceDelegate)
        case .tearDownSearcher:
            await searcher.tearDownSearcher(navigationItem: navigationItem, tableView: tableView)
        }
    }

    func present(_ state: ArtistsState) {
        activity.stopAnimating()
        title = switch state.listType {
        case .allArtists: "Artists"
        case .composers: "Composers"
        }

        Task {
            await searcher.setUpSearcher(navigationItem: navigationItem, updater: dataSourceDelegate)
        }

        navigationItem.leftBarButtonItem?.menu = menu(for: state.listType)
        dataSourceDelegate?.present(state)
    }

    private func menu(for listType: ArtistsState.ListType) -> UIMenu {
        switch listType {
        case .allArtists:
            UIMenu(title: "", options: [], children: [
                UIAction(title: "Composers", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.composers)
                    }
                }),
                UIAction(title: "Albums", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.albums)
                    }
                }),
            ])
        case .composers:
            UIMenu(title: "", options: [], children: [
                UIAction(title: "Artists", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.allArtists)
                    }
                }),
                UIAction(title: "Albums", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.albums)
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
