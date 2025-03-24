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

    lazy var tableHeaderView: UIView = {
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tableHeaderView.backgroundColor = .background
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Jukebox Mode: ", attributes: .init ([
            .font: UIFont(name: "GillSans-Bold", size: 15) as Any,
            .foregroundColor: UIColor.label,
        ]))
        config.image = UIImage(systemName: "rectangle")
        config.imagePlacement = .trailing
        config.imageColorTransformer = .init { _ in .label }
        let button = UIButton(configuration: config, primaryAction: UIAction() {
            [weak self] _ in self?.doJukeboxButton()
        })
        tableHeaderView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
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
        Task {
            await processor?.receive(.initialData)
        }
        if userHasJukeboxRole {
            tableView.tableHeaderView = tableHeaderView
        }
    }

    func present(_ state: PlaylistState) {
        dataSourceDelegate?.present(state)
        if let jukeboxButton = tableView.tableHeaderView?.subviews(ofType: UIButton.self).first {
            jukeboxButton.configuration?.image = if state.jukeboxMode {
                UIImage(systemName: "checkmark.rectangle")
            } else {
                UIImage(systemName: "rectangle")
            }
        }
        if let playPauseButton = navigationItem.rightBarButtonItems?[1] {
            playPauseButton.isEnabled = state.showPlayPauseButton
        }
        if let cancelButton = navigationItem.rightBarButtonItems?[0] {
            cancelButton.isEnabled = state.showClearButtonAndJukeboxButton
        }
        tableView.tableHeaderView?.subviews.forEach {
            $0.isHidden = !state.showClearButtonAndJukeboxButton
        }
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
}
