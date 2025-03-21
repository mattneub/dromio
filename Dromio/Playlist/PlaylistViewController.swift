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
        title = "Playlist"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var tableHeaderView: UIView = {
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tableHeaderView.backgroundColor = .tertiarySystemBackground
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Jukebox Mode: ", attributes: .init (
            [.font: UIFont(name: "GillSans-Bold", size: 15) as Any],
        ))
        config.image = UIImage(systemName: "rectangle")
        config.imagePlacement = .trailing
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
        let rightBarButtonItem = UIBarButtonItem(title: "Clear", image: nil, target: self, action: #selector(doClear))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        Task {
            await processor?.receive(.initialData)
        }
        if userHasJukeboxRole { // withdrawing this feature for now, alas
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
    }

    func receive(_ effect: PlaylistEffect) async {
        switch effect {
        case .deselectAll:
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        case .progress(let id, let progress):
            await dataSourceDelegate?.receive(.progress(id, progress))
        }
    }

    @objc func doClear() {
        Task {
            await processor?.receive(.clear)
        }
    }

    @objc func doJukeboxButton() {
        Task {
            await processor?.receive(.jukeboxButton)
        }
    }
}
