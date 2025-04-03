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
        dataSourceDelegate = AlbumsDataSourceDelegate(tableView: tableView)
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
        view.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerYAnchor).isActive = true
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        Task {
            await processor?.receive(.initialData)
        }
    }

    func receive(_ effect: AlbumsEffect) async {
        switch effect {
        case .scrollToZero:
            if tableView.window != nil {
                if !tableView.visibleCells.isEmpty && tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
                    tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
                }
            }
        case .setUpSearcher:
            await searcher.setUpSearcher(navigationItem: navigationItem, tableView: tableView, updater: dataSourceDelegate)
        case .tearDownSearcher:
            await searcher.tearDownSearcher(navigationItem: navigationItem, tableView: tableView)
        }
    }

    func present(_ state: AlbumsState) async {
        title = switch state.listType {
        case .allAlbums: 
            "All Albums"
        case .randomAlbums: 
            "Random Albums"
        case .albumsForArtist:
            nil
        }

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

        navigationItem.leftBarButtonItem = switch state.listType {
        case .allAlbums, .randomAlbums:
            UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"), menu: UIMenu())
        case .albumsForArtist:
            nil
        }

        navigationItem.leftBarButtonItem?.menu = menu(for: state.listType)
        await dataSourceDelegate?.present(state)
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
