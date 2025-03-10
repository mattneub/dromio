@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct RootCoordinatorTests {
    let requestMaker = MockRequestMaker()

    init() {
        // prevent accidental networking
        services.requestMaker = requestMaker
    }

    @Test("createInitialInterface: creates the initial interface and module")
    func createInitialInterface() throws {
        let subject = RootCoordinator()
        let window = UIWindow()
        subject.createInitialInterface(window: window)
        let pingProcessor = try #require(subject.pingProcessor as? PingProcessor)
        let rootViewController = try #require(subject.rootViewController as? UINavigationController)
        let pingViewController = try #require(rootViewController.viewControllers.first as? PingViewController)
        #expect(pingViewController.processor === pingProcessor)
        #expect(pingProcessor.presenter === pingViewController)
        #expect(pingProcessor.coordinator === subject)
    }

    @Test("showServer: configures server module, presents server view controller")
    func showServer() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        // ok, here we go!
        subject.showServer()
        await #while(subject.rootViewController?.presentedViewController == nil)
        let serverViewController = try #require(subject.rootViewController?.presentedViewController as? ServerViewController)
        #expect(serverViewController.modalPresentationStyle == .pageSheet)
        let serverProcessor = try #require(subject.serverProcessor as? ServerProcessor)
        #expect(serverViewController.processor === serverProcessor)
        #expect(serverProcessor.presenter === serverViewController)
        #expect(serverProcessor.coordinator === subject)
    }

    @Test("dismissServer: dismisses the server view controller, sends .doPing to the ping processor")
    func dismissServer() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let pingProcessor = MockProcessor<PingAction, PingState>()
        subject.pingProcessor = pingProcessor
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        // ok, here we go!
        subject.showServer()
        await #while(subject.rootViewController?.presentedViewController == nil)
        _ = try #require(subject.rootViewController?.presentedViewController as? ServerViewController)
        #expect(pingProcessor.thingsReceived.isEmpty)
        subject.dismissServer()
        await #while(subject.rootViewController?.presentedViewController != nil)
        #expect(subject.rootViewController?.presentedViewController == nil)
        #expect(pingProcessor.thingsReceived == [.doPing])
    }

    @Test("showAlbums: presents albums view controller, configures module")
    func showAlbums() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        // ok, here we go!
        subject.showAlbums()
        await #while(subject.rootViewController?.presentedViewController == nil)
        let navigationController = try #require(subject.rootViewController?.presentedViewController as? UINavigationController)
        #expect(navigationController.modalPresentationStyle == .fullScreen)
        let albumsViewController = try #require(navigationController.children.first as? AlbumsViewController)
        let albumsProcessor = try #require(subject.albumsProcessor as? AlbumsProcessor)
        #expect(albumsViewController.processor === albumsProcessor)
        #expect(albumsProcessor.presenter === albumsViewController)
        #expect(albumsProcessor.coordinator === subject)
    }

    @Test("showAlbumsForArtist: pushes albums view controller, configures module")
    func showAlbumsForArtist() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // ok, here we go!
        subject.showAlbumsForArtist(state: AlbumsState(listType: .albumsForArtist(id: "1")))
        await #while(presentedViewController.children.count < 2)
        let albumsViewController = try #require(presentedViewController.children[1] as? AlbumsViewController)
        let albumsProcessor = try #require(subject.artistAlbumsProcessor as? AlbumsProcessor)
        #expect(albumsProcessor.state == .init(listType: .albumsForArtist(id: "1")))
        #expect(albumsViewController.processor === albumsProcessor)
        #expect(albumsProcessor.presenter === albumsViewController)
        #expect(albumsProcessor.coordinator === subject)
    }

    @Test("showAlbum: pushes album view controller, configures module, sets processor state")
    func showAlbum() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // ok, here we go!
        subject.showAlbum(albumId: "1", title: "Album")
        await #while(presentedViewController.children.count < 2)
        let albumViewController = try #require(presentedViewController.children[1] as? AlbumViewController)
        let albumProcessor = try #require(subject.albumProcessor as? AlbumProcessor)
        #expect(albumProcessor.state == .init(albumId: "1", albumTitle: "Album"))
        #expect(albumViewController.processor === albumProcessor)
        #expect(albumProcessor.presenter === albumViewController)
        #expect(albumProcessor.coordinator === subject)
    }

    @Test("showArtists: presents artists view controller, configures module")
    func showArtists() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // ok, here we go!
        subject.showArtists()
        await #while(subject.rootViewController?.presentedViewController?.presentedViewController == nil)
        let navigationController = try #require(subject.rootViewController?.presentedViewController?.presentedViewController as? UINavigationController)
        #expect(navigationController.modalPresentationStyle == .fullScreen)
        #expect(navigationController.modalTransitionStyle == .flipHorizontal)
        let artistsViewController = try #require(navigationController.children.first as? ArtistsViewController)
        let artistsProcessor = try #require(subject.artistsProcessor as? ArtistsProcessor)
        #expect(artistsViewController.processor === artistsProcessor)
        #expect(artistsProcessor.presenter === artistsViewController)
        #expect(artistsProcessor.coordinator === subject)
    }

    @Test("dismissArtists: dismisses artists view controller")
    func dismissArtists() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        subject.showArtists()
        await #while(subject.rootViewController?.presentedViewController?.presentedViewController == nil)
        let navigationController = try #require(subject.rootViewController?.presentedViewController?.presentedViewController as? UINavigationController)
        let artistsViewController = try #require(navigationController.children.first as? ArtistsViewController)
        // ok, that was preparation, here we go
        subject.dismissArtists()
        await #while(subject.rootViewController?.presentedViewController?.presentedViewController != nil)
        #expect(navigationController.presentingViewController == nil)
        #expect(artistsViewController.view?.window == nil)
    }

    @Test("showPlaylist: pushes playlist view controller, configures module")
    func showPlaylist() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // ok, here we go!
        subject.showPlaylist()
        await #while(presentedViewController.children.count < 2)
        let playlistViewController = try #require(presentedViewController.children[1] as? PlaylistViewController)
        let playlistProcessor = try #require(subject.playlistProcessor as? PlaylistProcessor)
        #expect(playlistViewController.processor === playlistProcessor)
        #expect(playlistProcessor.presenter === playlistViewController)
        #expect(playlistProcessor.coordinator === subject)
    }

    @Test("showPlaylist: pushes playlist view controller onto second level presented view controller, configures module")
    func showPlaylistTwoLevels() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        subject.showArtists()
        await #while(subject.rootViewController?.presentedViewController?.presentedViewController == nil)
        let navigationController = try #require(subject.rootViewController?.presentedViewController?.presentedViewController as? UINavigationController)
        let _ = try #require(navigationController.children.first as? ArtistsViewController)
        // ok, here we go!
        subject.showPlaylist()
        await #while(navigationController.children.count < 2)
        let playlistViewController = try #require(navigationController.children[1] as? PlaylistViewController)
        let playlistProcessor = try #require(subject.playlistProcessor as? PlaylistProcessor)
        #expect(playlistViewController.processor === playlistProcessor)
        #expect(playlistProcessor.presenter === playlistViewController)
        #expect(playlistProcessor.coordinator === subject)
    }

    @Test("popPlaylist: pops the playlist view controller")
    func popPlaylist() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // still preparing
        subject.showPlaylist()
        await #while(presentedViewController.children.count < 2)
        let playlistViewController = try #require(presentedViewController.children[1] as? PlaylistViewController)
        #expect(playlistViewController.navigationController != nil)
        // ok, this is it!
        subject.popPlaylist()
        await #while(presentedViewController.children.count > 1)
        #expect(playlistViewController.navigationController == nil)
    }

}
