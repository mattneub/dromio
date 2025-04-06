import UIKit

final class AlbumsCellContentView: UIView, UIContentView {
    @IBOutlet var title: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet var tracks: UILabel!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        didSet {
            configureView(fromConfiguration: configuration)
        }
    }

    init(_ configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)

        let topLevelObjects = UINib(nibName: "AlbumsCellContentView", bundle: nil).instantiate(withOwner: self)
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
        guard let configuration = configuration as? AlbumsCellContentConfiguration else { return }
        title.text = configuration.title
        artist.text = configuration.artist
        tracks.text = configuration.tracks
    }
}

/// UIContentConfiguration for the item cell.
struct AlbumsCellContentConfiguration: UIContentConfiguration, Equatable {
    let title: String
    let artist: String
    let tracks: String

    /// The configuration must be created directly from an album.
    /// - Parameter album: The album.
    init(album: SubsonicAlbum) {
        self.title = album.name
        self.artist = album.artist.ensureNoBreakSpace
        self.tracks = String(
            AttributedString(
                localized: "^[\(album.songCount)\n\("track")](inflect: true)"
            ).characters
        )
    }

    func makeContentView() -> any UIView & UIContentView {
        return AlbumsCellContentView(self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}
