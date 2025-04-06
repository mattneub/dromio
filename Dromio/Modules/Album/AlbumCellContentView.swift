import UIKit

/// Content view for the item cell.
final class AlbumCellContentView: UIView, UIContentView {
    @IBOutlet var title: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet var count: UILabel!
    @IBOutlet var composer: UILabel!
    @IBOutlet var duration: UILabel!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        didSet {
            configureView(fromConfiguration: configuration)
        }
    }

    init(_ configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)

        let topLevelObjects = UINib(nibName: "AlbumCellContentView", bundle: nil).instantiate(withOwner: self)
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
        guard let configuration = configuration as? AlbumCellContentConfiguration else { return }
        title.text = configuration.title
        artist.text = configuration.artist
        count.text = String(configuration.number) + " of " + String(configuration.totalCount)
        duration.text = configuration.duration
        composer.text = configuration.composer
    }
}

/// Content configuration for the item cell.
struct AlbumCellContentConfiguration: UIContentConfiguration, Equatable {
    let title: String
    let artist: String
    let number: Int
    let totalCount: Int
    let duration: String
    let composer: String

    /// The configuration must be created directly from a song. We also need the total count for
    /// the album, which is not part of the song.
    /// - Parameters:
    ///   - song: The song.
    ///   - totalCount: The total count of songs in the album.
    init(song: SubsonicSong, totalCount: Int) {
        self.title = song.title
        self.artist = song.artist.ensureNoBreakSpace
        self.number = song.track ?? 0
        self.totalCount = totalCount
        self.duration = song.duration.map {
            Duration.seconds($0).formatted(
                .time(pattern: $0 >= 3600 ? .hourMinuteSecond : .minuteSecond)
            )
        } ?? ""
        let composer = song.displayComposer ?? ""
        let year = song.year.ensureNoBreakSpace
        self.composer = (composer.isEmpty ? "" : composer + " ") + year
    }

    func makeContentView() -> any UIView & UIContentView {
        return AlbumCellContentView(self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}

