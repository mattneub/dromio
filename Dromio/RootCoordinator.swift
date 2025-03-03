import UIKit

/// Protocol embodying the public interface for the root coordinator.
@MainActor
protocol RootCoordinatorType: AnyObject {
    // Processors are rooted here. They are all expressed as protocols, for testability.

    var pingProcessor: (any Processor<PingAction, PingState>)? { get }
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState>)? { get }
    var albumProcessor: (any Processor<AlbumAction, AlbumState>)? { get }
    var playlistProcessor: (any Processor<PlaylistAction, PlaylistState>)? { get }
    var serverProcessor: (any Processor<ServerAction, ServerState>)? { get }

    // The root coordinator also needs a reference to the true root view controller.

    var rootViewController: UIViewController? { get set }

    /// Create the entire initial interface and modules, rooted in the given window.
    /// - Parameter window: The window
    func createInitialInterface(window: UIWindow)

    /// Create the Server module and show the view controller.
    func showServer()

    /// Dismiss the Server module's view controller.
    func dismissServer()

    /// Create the Albums module and show the view controller.
    func showAlbums()

    /// Create the Album module and show the view controller.
    func showAlbum(albumId: String)

    /// Create the Playlist module and show the view controller.
    func showPlaylist()
}

/// Class of single instance responsible for all view controller manipulation.
@MainActor
final class RootCoordinator: RootCoordinatorType {

    var pingProcessor: (any Processor<PingAction, PingState>)?
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState>)?
    var albumProcessor: (any Processor<AlbumAction, AlbumState>)?
    var playlistProcessor: (any Processor<PlaylistAction, PlaylistState>)?
    var serverProcessor: (any Processor<ServerAction, ServerState>)?

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

    func showServer() {
        let serverController = ServerViewController(nibName: "Server", bundle: nil)
        let serverProcessor = ServerProcessor()
        self.serverProcessor = serverProcessor
        serverProcessor.presenter = serverController
        serverController.processor = serverProcessor
        serverProcessor.coordinator = self
        serverController.modalPresentationStyle = .pageSheet
        rootViewController?.present(serverController, animated: unlessTesting(true))
    }

    func dismissServer() {
        guard let serverController = rootViewController?.presentedViewController as? ServerViewController else {
            return
        }
        serverController.dismiss(animated: unlessTesting(true)) {
            Task {
                await self.pingProcessor?.receive(.doPing)
            }
        }
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

    func showAlbum(albumId: String) {
        let albumController = AlbumViewController(nibName: nil, bundle: nil)
        let albumProcessor = AlbumProcessor()
        albumProcessor.state.albumId = albumId
        self.albumProcessor = albumProcessor
        albumProcessor.presenter = albumController
        albumController.processor = albumProcessor
        albumProcessor.coordinator = self
        guard let navigationController = rootViewController?.presentedViewController as? UINavigationController else {
            return
        }
        navigationController.pushViewController(albumController, animated: unlessTesting(true))
    }

    func showPlaylist() {
        let playlistController = PlaylistViewController(nibName: nil, bundle: nil)
        let playlistProcessor = PlaylistProcessor()
        self.playlistProcessor = playlistProcessor
        playlistProcessor.presenter = playlistController
        playlistController.processor = playlistProcessor
        playlistProcessor.coordinator = self
        guard let navigationController = rootViewController?.presentedViewController as? UINavigationController else {
            return
        }
        navigationController.pushViewController(playlistController, animated: unlessTesting(true))
    }
}

