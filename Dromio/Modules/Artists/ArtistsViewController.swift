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

    /// Object that handles and configures our search controller; it's a var for testing purposes.
    var searcher = Searcher()

    let activity: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .large)
        activity.color = .label
        activity.backgroundColor = UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light: UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .dark))
            default: UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light))
            }
        })
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.widthAnchor.constraint(equalToConstant: 100).isActive = true
        activity.heightAnchor.constraint(equalToConstant: 100).isActive = true
        activity.layer.cornerRadius = 20
        return activity
    }()

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
        view.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerYAnchor).isActive = true
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        Task {
            await processor?.receive(.viewIsAppearing)
        }
    }

    func receive(_ effect: ArtistsEffect) async {
        switch effect {
        case .scrollToZero:
            if tableView.window != nil {
                if !tableView.visibleCells.isEmpty && tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
                    tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
                }
            }
        case .setUpSearcher:
            await searcher.setUpSearcher(navigationItem: navigationItem, tableView: tableView, updater: dataSourceDelegate)
        }
    }

    func present(_ state: ArtistsState) async {
        title = switch state.listType {
        case .allArtists: "Artists"
        case .composers: "Composers"
        }
        navigationItem.leftBarButtonItem?.menu = menu(for: state.listType)

        switch state.animateSpinner {
        case true:
            if !activity.isAnimating {
                activity.startAnimating()
                activity.window?.isUserInteractionEnabled = false
            }
        case false:
            if activity.isAnimating {
                activity.stopAnimating()
                activity.window?.isUserInteractionEnabled = true
            }
        }

        await dataSourceDelegate?.present(state)
    }

    
    /// Utility that supplies the UIMenu depending on the list type.
    /// - Parameter listType: The list type.
    /// - Returns: The menu.
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
                UIAction(title: "Server", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.server)
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
                UIAction(title: "Server", handler: { [weak self] _ in
                    Task {
                        await self?.processor?.receive(.server)
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

    deinit {
        logger.log("farewell from artists")
    }
}
