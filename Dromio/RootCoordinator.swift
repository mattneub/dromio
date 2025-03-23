import UIKit

/// Protocol embodying the public interface for the root coordinator.
@MainActor
protocol RootCoordinatorType: AnyObject {
    // Processors are rooted here. They are all expressed as protocols, for testability.

    var pingProcessor: (any Processor<PingAction, PingState, Void>)? { get }
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState, AlbumsEffect>)? { get }
    var albumProcessor: (any Processor<AlbumAction, AlbumState, AlbumEffect>)? { get }
    var artistsProcessor: (any Processor<ArtistsAction, ArtistsState, ArtistsEffect>)? { get }
    var artistAlbumsProcessor: (any Processor<AlbumsAction, AlbumsState, AlbumsEffect>)? { get }
    var playlistProcessor: (any Processor<PlaylistAction, PlaylistState, PlaylistEffect>)? { get }
    var serverProcessor: (any Processor<ServerAction, ServerState, Void>)? { get }

    // The root coordinator also needs a reference to the true root view controller.

    var rootViewController: UIViewController? { get set }

    /// Create the entire initial interface and modules, rooted in the given window.
    /// - Parameter window: The window
    func createInitialInterface(window: UIWindow)

    /// Create the Server module and show the view controller.
    func showServer(delegate: any ServerDelegate)

    /// Dismiss all presented controllers to return to the ping view.
    func dismissToPing()

    /// Create the Albums module and show the view controller.
    func showAlbums()

    /// Create the Albums module and push the view controller, passing the processor the given state.
    func showAlbumsForArtist(state: AlbumsState)

    /// Create the Album module and show the view controller.
    /// - Parameters:
    ///   - albumId: The id of the album whose songs we are to display.
    ///   - title: The album's title, to be displayed as the view controller title.
    ///
    /// We pass this info from the caller because we want the view controller to know the
    /// title regardless of when the processor fetches the songs.
    func showAlbum(albumId: String, title: String)

    /// Create the Artists module and show the view controller.
    func showArtists()

    /// Dismiss the Artists view controller.
    func dismissArtists()

    /// Create the Playlist module and show the view controller.
    func showPlaylist(state: PlaylistState?)

    /// Pop the Playlist view controller.
    func popPlaylist()

    /// Show a simple alert with an OK button.
    func showAlert(title: String?, message: String?)

    /// Show a simple action sheet.
    func showActionSheet(title: String, options: [String]) async -> String?
}

/// Class of single instance responsible for all view controller manipulation.
@MainActor
final class RootCoordinator: RootCoordinatorType {

    var pingProcessor: (any Processor<PingAction, PingState, Void>)?
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState, AlbumsEffect>)?
    var albumProcessor: (any Processor<AlbumAction, AlbumState, AlbumEffect>)?
    var artistsProcessor: (any Processor<ArtistsAction, ArtistsState, ArtistsEffect>)?
    // The albums module can appear in two places simultaneously, so we need a place to root
    // a second instance of the albums processor.
    var artistAlbumsProcessor: (any Processor<AlbumsAction, AlbumsState, AlbumsEffect>)?
    var playlistProcessor: (any Processor<PlaylistAction, PlaylistState, PlaylistEffect>)?
    var serverProcessor: (any Processor<ServerAction, ServerState, Void>)?

    weak var rootViewController: UIViewController?

    func createInitialInterface(window: UIWindow) {
        let pingController = PingViewController(nibName: "Ping", bundle: nil)
        let navigationController = UINavigationController(rootViewController: pingController)
        window.rootViewController = navigationController
        self.rootViewController = window.rootViewController
        let pingProcessor = PingProcessor()
        self.pingProcessor = pingProcessor
        pingProcessor.presenter = pingController
        pingController.processor = pingProcessor
        pingProcessor.coordinator = self
    }

    func showServer(delegate: any ServerDelegate) {
        let serverController = ServerViewController(nibName: "Server", bundle: nil)
        let serverProcessor = ServerProcessor()
        self.serverProcessor = serverProcessor
        serverProcessor.presenter = serverController
        serverProcessor.delegate = delegate
        serverController.processor = serverProcessor
        serverProcessor.coordinator = self
        serverController.modalPresentationStyle = .pageSheet
        rootViewController?.present(serverController, animated: unlessTesting(true))
    }

    func dismissToPing() {
        rootViewController?.dismiss(animated: unlessTesting(true))
    }

    func showAlbums() {
        let albumsController = AlbumsViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: albumsController)
        let albumsProcessor = AlbumsProcessor()
        self.albumsProcessor = albumsProcessor
        albumsProcessor.presenter = albumsController
        albumsController.processor = albumsProcessor
        albumsProcessor.coordinator = self
        navigationController.modalPresentationStyle = .fullScreen
        rootViewController?.present(navigationController, animated: unlessTesting(true))
    }

    func showAlbumsForArtist(state: AlbumsState) {
        let albumsController = AlbumsViewController(nibName: nil, bundle: nil)
        let albumsProcessor = AlbumsProcessor()
        self.artistAlbumsProcessor = albumsProcessor // different from self.albumsProcessor
        albumsProcessor.state = state
        albumsProcessor.presenter = albumsController
        albumsController.processor = albumsProcessor
        albumsProcessor.coordinator = self
        guard let navigationController = rootViewController?.ultimatePresented as? UINavigationController else {
            return
        }
        navigationController.pushViewController(albumsController, animated: unlessTesting(true))
    }

    func showAlbum(albumId: String, title: String) {
        let albumController = AlbumViewController(nibName: nil, bundle: nil)
        let albumProcessor = AlbumProcessor()
        albumProcessor.state = AlbumState(albumId: albumId, albumTitle: title, songs: [])
        self.albumProcessor = albumProcessor
        albumProcessor.presenter = albumController
        albumController.processor = albumProcessor
        albumProcessor.coordinator = self
        guard let navigationController = rootViewController?.ultimatePresented as? UINavigationController else {
            return
        }
        navigationController.pushViewController(albumController, animated: unlessTesting(true))
    }

    func showArtists() {
        let artistsController = ArtistsViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: artistsController)
        let artistsProcessor = ArtistsProcessor()
        self.artistsProcessor = artistsProcessor
        artistsProcessor.presenter = artistsController
        artistsController.processor = artistsProcessor
        artistsProcessor.coordinator = self
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        rootViewController?.presentedViewController?.present(navigationController, animated: unlessTesting(true))
    }

    func dismissArtists() {
        (artistsProcessor?.presenter as? UIViewController)?.dismiss(animated: unlessTesting(true))
    }

    func showPlaylist(state: PlaylistState?) {
        let playlistController = PlaylistViewController(nibName: nil, bundle: nil)
        let playlistProcessor = PlaylistProcessor()
        self.playlistProcessor = playlistProcessor
        if let state {
            playlistProcessor.state = state
        }
        playlistProcessor.presenter = playlistController
        playlistController.processor = playlistProcessor
        playlistProcessor.coordinator = self
        guard let navigationController = rootViewController?.ultimatePresented as? UINavigationController else {
            return
        }
        navigationController.pushViewController(playlistController, animated: unlessTesting(true))
    }

    func popPlaylist() {
        guard let navigationController = rootViewController?.ultimatePresented as? UINavigationController else {
            return
        }
        navigationController.popViewController(animated: unlessTesting(true))
    }

    func showAlert(title: String?, message: String?) {
        guard !(title == nil && message == nil) else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        rootViewController?.ultimatePresented.present(alert, animated: unlessTesting(true))
    }

    func showActionSheet(title: String, options: [String]) async -> String? {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            for option in options {
                alert.addAction(AlertAction(title: option, style: .default, handler: { action in
                    continuation.resume(returning: action.title)
                }))
            }
            alert.addAction(AlertAction(title: "Cancel", style: .cancel, handler: { _ in
                continuation.resume(returning: nil)
            }))
            rootViewController?.present(alert, animated: unlessTesting(true))
        }
    }
}
