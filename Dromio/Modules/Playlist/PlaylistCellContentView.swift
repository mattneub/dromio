import UIKit

/// Content view for the item cell.
final class PlaylistCellContentView: UIView, UIContentView {
    @IBOutlet var title: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet var album: UILabel!
    @IBOutlet var composer: UILabel!
    @IBOutlet var duration: UILabel!
    @IBOutlet var thermometer: ThermometerView!
    @IBOutlet var nowPlaying: UIImageView!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        didSet {
            configureView(fromConfiguration: configuration)
        }
    }

    init(_ configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)

        let topLevelObjects = UINib(nibName: "PlaylistCellContentView", bundle: nil).instantiate(withOwner: self)
        guard let loadedView = topLevelObjects.first as? UIView else { return }
        loadedView.backgroundColor = nil
        self.addSubview(loadedView)
        loadedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadedView.topAnchor.constraint(equalTo: topAnchor),
            loadedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            loadedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadedView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        configureView(fromConfiguration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView(fromConfiguration configuration: any UIContentConfiguration) {
        guard let configuration = configuration as? PlaylistCellContentConfiguration else { return }
        title.text = configuration.title
        artist.text = configuration.artist
        album.text = configuration.album
        duration.text = configuration.duration
        composer.text = configuration.composer
        nowPlaying.isHidden = !configuration.nowPlaying
    }
}

/// Content configuration for the item cell.
struct PlaylistCellContentConfiguration: UIContentConfiguration, Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: String
    let composer: String
    let nowPlaying: Bool

    /// The configuration must be created directly from a song.
    /// - Parameters:
    ///   - song: The song.
    init(song: SubsonicSong, currentSongId: String? = nil) {
        self.title = song.title
        self.artist = song.artist.ensureNoBreakSpace
        self.album = song.album.ensureNoBreakSpace
        self.duration = song.duration.map {
            Duration.seconds($0).formatted(
                .time(pattern: $0 >= 3600 ? .hourMinuteSecond : .minuteSecond)
            )
        } ?? ""
        let composer = song.displayComposer ?? ""
        let year = song.year.ensureNoBreakSpace
        self.composer = (composer.isEmpty ? "" : composer + " ") + year
        self.nowPlaying = currentSongId == song.id
    }

    func makeContentView() -> any UIView & UIContentView {
        return PlaylistCellContentView(self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}

