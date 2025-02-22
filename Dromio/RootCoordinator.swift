import UIKit

/// Protocol embodying the public interface for the root coordinator.
@MainActor
protocol RootCoordinatorType: AnyObject {
    // Processors are rooted here. They are all expressed as protocols, for testability.

    var pingProcessor: (any Processor<PingAction, PingState>)? { get }
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState>)? { get }
    var albumProcessor: (any Processor<AlbumAction, AlbumState>)? { get }

    // The root coordinator also needs a reference to the true root view controller.

    var rootViewController: UIViewController? { get set }

    /// Create the entire initial interface and modules, rooted in the given window.
    /// - Parameter window: The window
    func createInitialInterface(window: UIWindow)

    /// Create the Albums module and show the view controller.
    func showAlbums()

    /// Create the Album module and show the view controller.
    func showAlbum(albumId: String)

}

/// Class of single instance responsible for all view controller manipulation.
@MainActor
final class RootCoordinator: RootCoordinatorType {

    var pingProcessor: (any Processor<PingAction, PingState>)?
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState>)?
    var albumProcessor: (any Processor<AlbumAction, AlbumState>)?

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

    func showAlbums() {
        let albumsController = AlbumsViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: albumsController)
        let albumsProcessor = AlbumsProcessor()
        self.albumsProcessor = albumsProcessor
        albumsProcessor.presenter = albumsController
        albumsController.processor = albumsProcessor
        albumsProcessor.coordinator = self
        navigationController.modalPresentationStyle = .fullScreen
        rootViewController?.present(navigationController, animated: true)
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
        navigationController.pushViewController(albumController, animated: true)
    }
}

