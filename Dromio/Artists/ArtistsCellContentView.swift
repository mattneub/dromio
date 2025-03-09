import UIKit

final class ArtistsCellContentView: UIView, UIContentView {
    @IBOutlet var name: UILabel!
    @IBOutlet var albums: UILabel!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        didSet {
            configureView(fromConfiguration: configuration)
        }
    }

    init(_ configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)

        let topLevelObjects = UINib(nibName: "ArtistsCellContentView", bundle: nil).instantiate(withOwner: self)
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
        guard let configuration = configuration as? ArtistsCellContentConfiguration else { return }
        name.text = configuration.name
        albums.text = configuration.albums
    }
}

/// UIContentConfiguration for the item cell.
struct ArtistsCellContentConfiguration: UIContentConfiguration, Equatable {
    let name: String
    let albums: String

    /// The configuration must be created directly from an artist.
    /// - Parameter artist: The artist.
    init(artist: SubsonicArtist) {
        self.name = artist.name
        self.albums = String(
            AttributedString(
                localized: "^[\(artist.albumCount ?? 0)\n\("album")](inflect: true)"
            ).characters
        )
    }

    func makeContentView() -> any UIView & UIContentView {
        return ArtistsCellContentView(self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}
