import UIKit

/// View controller that displays a list of all songs in an album.
final class PlaylistViewController: UITableViewController, ReceiverPresenter {
    /// Data source and delegate object, created in `init`.
    var dataSourceDelegate: (any DataSourceDelegate<PlaylistAction, PlaylistState, PlaylistEffect>)?

    /// Reference to the processor, set by coordinator on creation; setting it passes the same processor to the data source.
    weak var processor: (any Receiver<PlaylistAction>)? {
        didSet {
            dataSourceDelegate?.processor = processor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSourceDelegate = PlaylistDataSourceDelegate(tableView: tableView)
        tableView.estimatedRowHeight = 90
        title = "Queue"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var jukeboxButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config, primaryAction: UIAction() {
            [weak self] _ in self?.doJukeboxButton()
        })
        config.attributedTitle = AttributedString("Jukebox Mode: ", attributes: .init ([
            .font: UIFont(name: "GillSans-Bold", size: 15) as Any,
            .foregroundColor: UIColor.label,
        ]))
        config.titleTextAttributesTransformer = .init({ [weak button] container in
            guard let button else { return container }
            var container = container
            container.foregroundColor = button.isEnabled ? UIColor.label : UIColor.systemGray
            return container
        })
        config.image = UIImage(systemName: "rectangle")
        config.imagePlacement = .trailing
        config.imageColorTransformer = .init({ [weak button] _ in
            guard let button else { return .label }
            return button.isEnabled ? .label : .systemGray
        })
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40)).applying { tableHeaderView in
        tableHeaderView.backgroundColor = .background
        tableHeaderView.addSubview(jukeboxButton)
        NSLayoutConstraint.activate([
            jukeboxButton.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            jukeboxButton.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
        ])
    }

    lazy var clearItem = UIBarButtonItem(
        title: nil,
        image: UIImage(systemName: "clear.fill"),
        target: self,
        action: #selector(doClear)
    )

    lazy var pauseItem = UIBarButtonItem(
        title: nil,
        image: UIImage(systemName: "playpause.fill"),
        target: self,
        action: #selector(doPlayPause)
    )


    /// Temporary holding tank for any state that arrives while the table view has a selection; we
    /// don't want to present when it does, because that will cancel the selection.
    var postponedState: PlaylistState?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .background
        pauseItem.width = 58
        pauseItem.isSymbolAnimationEnabled = true
        navigationItem.rightBarButtonItems = [clearItem, UIBarButtonItem.fixedSpace(), pauseItem]
        let scissorsItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "scissors"), target: self, action: #selector(doEdit))
        navigationItem.leftBarButtonItem = scissorsItem
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.titleView = UILabel().applying {
            $0.text = "Queue"
            $0.font = UIFont(name: "Verdana-Bold", size: 17)
            $0.numberOfLines = 2
            $0.textAlignment = .center
            $0.minimumScaleFactor = 0.8
            $0.adjustsFontSizeToFitWidth = true
        }
        Task {
            await processor?.receive(.initialData)
        }
        if userHasJukeboxRole {
            tableView.tableHeaderView = tableHeaderView
        }
    }

    func present(_ state: PlaylistState) async {
        jukeboxButton.configuration?.image = if state.jukeboxMode {
            UIImage(systemName: "checkmark.rectangle")
        } else {
            UIImage(systemName: "rectangle")
        }
        if let editButton = navigationItem.leftBarButtonItem {
            editButton.image = if state.editMode {
                UIImage(systemName: "checkmark")
            } else {
                UIImage(systemName: "scissors")
            }
        }
        pauseItem.isEnabled = state.showPlayPauseButton
        clearItem.isEnabled = state.showClearButtonAndJukeboxButton
        jukeboxButton.isEnabled = state.showClearButtonAndJukeboxButton
        if isEditing != state.editMode {
            setEditing(state.editMode, animated: unlessTesting(true))
            if self.tableView.window != nil {
                UIView.performWithoutAnimation {
                    self.tableView?.beginUpdates()
                    self.tableView?.endUpdates()
                }
            }
        }
        if tableView.indexPathForSelectedRow == nil {
            await dataSourceDelegate?.present(state)
        } else { // if there is currently a selection, postpone presentation until there isn't
            self.postponedState = state
        }
    }

    func receive(_ effect: PlaylistEffect) async {
        switch effect {
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
            if let state = postponedState {
                await dataSourceDelegate?.present(state)
                postponedState = nil
            }
        case .playerState(let playerState):
            switch playerState {
            case .empty:
                let image = UIImage(systemName: "playpause.fill")!
                pauseItem.image = image
            case .paused:
                let image = UIImage(systemName: "play.fill")!
                pauseItem.setSymbolImage(image, contentTransition: .replace.offUp)
            case .playing:
                let image = UIImage(systemName: "pause.fill")!
                pauseItem.setSymbolImage(image, contentTransition: .replace.offUp)
            }
        case .progress(let id, let progress):
            await dataSourceDelegate?.receive(.progress(id, progress))
        }
    }

    @objc func doClear() {
        Task {
            await processor?.receive(.clear)
        }
    }

    @objc func doPlayPause() {
        Task {
            await processor?.receive(.playPause)
        }
    }

    @objc func doJukeboxButton() {
        Task {
            await processor?.receive(.jukeboxButton)
        }
    }

    @objc func doEdit() {
        Task {
            await processor?.receive(.editButton)
        }
    }
}
