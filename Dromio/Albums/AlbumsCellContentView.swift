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

    /// This view (the ItemCellContentView) is itself just a blank. It gets its content by
    /// loading it from a nib (thus also filling the outlets) and adding that content as subview.
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

    /// The actual response to the configuration is simply to assign each property of the
    /// configuration into its corresponding outlet view.
    func configureView(fromConfiguration configuration: any UIContentConfiguration) {
        guard let configuration = configuration as? AlbumsCellContentConfiguration else { return }
        title.text = configuration.title
        artist.text = configuration.artist
        tracks.text = String(
            AttributedString(
                localized: "^[\(configuration.tracks)\n\("track")](inflect: true)"
            ).characters
        )
    }
}

/// UIContentConfiguration for the item cell.
struct AlbumsCellContentConfiguration: UIContentConfiguration {
    var title = " "
    var artist = " "
    var tracks = 0

    func makeContentView() -> any UIView & UIContentView {
        return AlbumsCellContentView(self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}
