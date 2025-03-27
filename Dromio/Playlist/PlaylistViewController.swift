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

    lazy var tableHeaderView: UIView = {
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tableHeaderView.backgroundColor = .background
        tableHeaderView.addSubview(jukeboxButton)
        NSLayoutConstraint.activate([
            jukeboxButton.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            jukeboxButton.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
        ])
        return tableHeaderView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourceDelegate?.processor = processor
        view.backgroundColor = .background
        let clearItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "clear.fill"), target: self, action: #selector(doClear))
        let pauseItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "playpause.fill"), target: self, action: #selector(doPlayPause))
        pauseItem.width = 40
        pauseItem.isSymbolAnimationEnabled = true
        navigationItem.rightBarButtonItems = [clearItem, pauseItem]
        let scissorsItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "scissors"), target: self, action: #selector(doEdit))
        navigationItem.leftBarButtonItem = scissorsItem
        navigationItem.leftItemsSupplementBackButton = true
        Task {
            await processor?.receive(.initialData)
        }
        if userHasJukeboxRole {
            tableView.tableHeaderView = tableHeaderView
        }
    }

    func present(_ state: PlaylistState) {
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
        if let playPauseButton = navigationItem.rightBarButtonItems?[1] {
            playPauseButton.isEnabled = state.showPlayPauseButton
        }
        if let cancelButton = navigationItem.rightBarButtonItems?[0] {
            cancelButton.isEnabled = state.showClearButtonAndJukeboxButton
        }
        jukeboxButton.isEnabled = state.showClearButtonAndJukeboxButton
        if isEditing != state.editMode {
            setEditing(state.editMode, animated: unlessTesting(true))
            UIView.performWithoutAnimation {
                self.tableView?.beginUpdates()
                self.tableView?.endUpdates()
            }
        }
        dataSourceDelegate?.present(state)
    }

    func receive(_ effect: PlaylistEffect) async {
        switch effect {
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        case .playerState(let playerState):
            if let playPauseButton = navigationItem.rightBarButtonItems?[1] {
                switch playerState {
                case .empty:
                    let image = UIImage(systemName: "playpause.fill")!
                    playPauseButton.setSymbolImage(image, contentTransition: .replace.offUp)
                case .paused:
                    let image = UIImage(systemName: "play.fill")!
                    playPauseButton.setSymbolImage(image, contentTransition: .replace.offUp)
                case .playing:
                    let image = UIImage(systemName: "pause.fill")!
                    playPauseButton.setSymbolImage(image, contentTransition: .replace.offUp)
                }
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
