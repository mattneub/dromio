import UIKit

/// View controller that displays a list of all songs in an album.
final class AlbumViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object.
    lazy var dataSourceDelegate: (any DataSourceDelegateSearcher<AlbumAction, AlbumState, Void>) = AlbumDataSourceDelegate(tableView: tableView)

    /// Helper object containing boilerplate for setting up search field.
    lazy var searchConfigurator: SearchConfigurator = SearchConfigurator()

    /// Reference to the processor, set by coordinator on creation.
    weak var processor: (any Receiver<AlbumAction>)?

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

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate.processor = processor
        view.backgroundColor = .background
        view.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerYAnchor).isActive = true
        let item = UIBarButtonItem(title: nil, image: UIImage(systemName: "list.bullet"), target: self, action: #selector(showPlaylist))
        item.isSymbolAnimationEnabled = true
        navigationItem.rightBarButtonItem = item
        searchConfigurator.configure(viewController: self, updater: dataSourceDelegate)
        tableView.estimatedRowHeight = 90
        tableView.sectionHeaderTopPadding = 0
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: AlbumState) async {
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
        await dataSourceDelegate.present(state)
    }

    func receive(_ effect: AlbumEffect) async {
        switch effect {
        case .animate(let song):
            guard let indexPath = dataSourceDelegate.indexPath(forDatum: song.id) else { return }
            await animate(indexPath: indexPath)
        case .animatePlaylist:
            navigationItem.rightBarButtonItem?.addSymbolEffect(.bounce, options: .nonRepeating)
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        case .scrollToZero:
            if tableView.window != nil {
                if !tableView.visibleCells.isEmpty && tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
                    tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
                }
            }
        }
    }

    /// Private utility that animates a snapshot of the given row to the (approximate) position of the
    /// left bar button item (a bar button item has no frame so we have to guess where it is).
    /// - Parameter row: The row.
    private func animate(indexPath: IndexPath) async {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        guard let window = cell.window else { return }
        guard let navigationController else { return }
        guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { return }
        let navBar = navigationController.navigationBar
        let navBarFrame = navBar.convert(navBar.bounds, to: nil) // window coordinates
        let initialFrame = cell.convert(cell.bounds, to: nil) // window coordinates
        snapshot.frame = initialFrame
        window.addSubview(snapshot)
        let finalCenter = CGPoint(x: navBarFrame.maxX - 30 - navBar.safeAreaInsets.right, y: navBarFrame.minY + 20) // or thereabouts
        await UIView.animate(.interpolatingSpring) {
            snapshot.center = finalCenter
            snapshot.transform = .init(scaleX: 0.05, y: 0.05)
        }
        snapshot.removeFromSuperview()
    }

    @objc func showPlaylist() {
        Task {
            await processor?.receive(.showPlaylist)
        }
    }

    isolated
    deinit {
        logger.debug("farewell from album")
    }
}
