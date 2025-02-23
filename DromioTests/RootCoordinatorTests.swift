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

    @Test("showAlbum: pushes album view controller, configures module")
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
        subject.showAlbum(albumId: "1")
        await #while(presentedViewController.children.count < 2)
        let albumViewController = try #require(presentedViewController.children[1] as? AlbumViewController)
        let albumProcessor = try #require(subject.albumProcessor as? AlbumProcessor)
        #expect(albumViewController.processor === albumProcessor)
        #expect(albumProcessor.presenter === albumViewController)
        #expect(albumProcessor.coordinator === subject)
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

}
