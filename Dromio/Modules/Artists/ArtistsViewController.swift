import UIKit

/// View controller that displays a list of all artists.
final class ArtistsViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object.
    lazy var dataSourceDelegate: (any DataSourceDelegateSearcher<ArtistsAction, ArtistsState, Void>) = ArtistsDataSourceDelegate(tableView: tableView)

    /// Helper object containing boilerplate for setting up search field.
    lazy var searchConfigurator: SearchConfigurator = SearchConfigurator()

    /// Reference to the processor, set by coordinator on creation.
    weak var processor: (any Receiver<ArtistsAction>)?

    let activity = UIActivityIndicatorView(style: .large).applying { activity in
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate.processor = processor
        view.backgroundColor = .background
        view.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerYAnchor).isActive = true
        searchConfigurator.configure(viewController: self, updater: dataSourceDelegate)
        let itemRight = UIBarButtonItem(title: nil, image: UIImage(systemName: "list.bullet"), target: self, action: #selector(showPlaylist))
        navigationItem.rightBarButtonItem = itemRight
        let menu = UIMenu() // real menu will be provided by `present`
        let itemLeft = UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.turn.up.right.circle"), menu: menu)
        navigationItem.leftBarButtonItem = itemLeft
        tableView.estimatedRowHeight = 40
        tableView.sectionIndexColor = .systemRed
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
        }
    }

    func present(_ state: ArtistsState) async {
        let title = switch state.listType {
        case .allArtists: "Artists"
        case .composers: "Composers"
        }
        if state.showTitle, let font = UIFont(name: "Verdana-Bold", size: 17) {
            navigationItem.attributedTitle = AttributedString(
                title,
                attributes: AttributeContainer.font(font)
            )
            navigationItem.subtitle = state.currentFolder
        } else {
            navigationItem.title = nil
            navigationItem.subtitle = nil
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

        await dataSourceDelegate.present(state)
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

    isolated
    deinit {
        unlessTesting {
            logger.debug("farewell from artists")
        }
    }
}
