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

    @Test("showServer: configures server module, presents server view controller, setting delegate")
    func showServer() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let delegate = MockServerDelegate()
        // ok, here we go!
        subject.showServer(delegate: delegate)
        await #while(subject.rootViewController?.presentedViewController == nil)
        let serverViewController = try #require(subject.rootViewController?.presentedViewController as? ServerViewController)
        #expect(serverViewController.modalPresentationStyle == .pageSheet)
        let serverProcessor = try #require(subject.serverProcessor as? ServerProcessor)
        #expect(serverViewController.processor === serverProcessor)
        #expect(serverProcessor.presenter === serverViewController)
        #expect(serverProcessor.coordinator === subject)
        #expect(serverProcessor.delegate === delegate)
    }

    @Test("dismissToPing: dismisses everything down to the ping view controller")
    func dismissToPing() async {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let pingProcessor = MockProcessor<PingAction, PingState, Void>()
        subject.pingProcessor = pingProcessor
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presented1 = UIViewController()
        rootViewController.present(presented1, animated: false)
        await #while(rootViewController.presentedViewController != presented1)
        let presented2 = UIViewController()
        presented1.present(presented2, animated: false)
        await #while(presented1.presentedViewController != presented2)
        // okay, here we go!
        subject.dismissToPing()
        await #while(rootViewController.presentedViewController != nil)
        #expect(rootViewController.presentedViewController == nil)
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
        subject.showAlbumsForArtist(state: AlbumsState(listType: .albumsForArtist(id: "1", source: .artists)))
        await #while(presentedViewController.children.count < 2)
        let albumsViewController = try #require(presentedViewController.children[1] as? AlbumsViewController)
        let albumsProcessor = try #require(subject.artistAlbumsProcessor as? AlbumsProcessor)
        #expect(albumsProcessor.state == .init(listType: .albumsForArtist(id: "1", source: .artists)))
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
        #expect(albumProcessor.state.albumId == "1")
        #expect(albumProcessor.state.albumTitle == "Album")
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
        #expect(navigationController.modalTransitionStyle == .crossDissolve)
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
        let mockAlbumsProcessor = MockProcessor<AlbumsAction, AlbumsState, AlbumsEffect>()
        subject.albumsProcessor = mockAlbumsProcessor
        // ok, that was preparation, here we go
        subject.dismissArtists()
        await #while(subject.rootViewController?.presentedViewController?.presentedViewController != nil)
        #expect(navigationController.presentingViewController == nil)
        #expect(artistsViewController.view?.window == nil)
        await #while(mockAlbumsProcessor.thingsReceived.isEmpty)
        #expect(mockAlbumsProcessor.thingsReceived == [.allAlbums])
    }

    @Test("showPlaylist: pushes playlist view controller onto base level, configures module")
    func showPlaylist() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        makeWindow(viewController: navigationController)
        subject.rootViewController = navigationController
        // ok, here we go!
        subject.showPlaylist(state: nil)
        await #while(navigationController.children.count < 2)
        let playlistViewController = try #require(navigationController.children[1] as? PlaylistViewController)
        let playlistProcessor = try #require(subject.playlistProcessor as? PlaylistProcessor)
        #expect(playlistViewController.processor === playlistProcessor)
        #expect(playlistProcessor.presenter === playlistViewController)
        #expect(playlistProcessor.coordinator === subject)
    }

    @Test("showPlaylist: pushes playlist view controller onto first level presented view controller, configures module")
    func showPlaylistOneLevel() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let presentedViewController = UINavigationController(rootViewController: UIViewController())
        rootViewController.present(presentedViewController, animated: false)
        await #while(rootViewController.presentedViewController == nil)
        // ok, here we go!
        subject.showPlaylist(state: nil)
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
        subject.showPlaylist(state: nil)
        await #while(navigationController.children.count < 2)
        let playlistViewController = try #require(navigationController.children[1] as? PlaylistViewController)
        let playlistProcessor = try #require(subject.playlistProcessor as? PlaylistProcessor)
        #expect(playlistViewController.processor === playlistProcessor)
        #expect(playlistProcessor.presenter === playlistViewController)
        #expect(playlistProcessor.coordinator === subject)
    }

    @Test("showPlaylist: passes state, if not nil, on to playlist processor")
    func showPlaylistState() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let rootViewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        makeWindow(viewController: navigationController)
        subject.rootViewController = navigationController
        // ok, here we go!
        subject.showPlaylist(state: .init(offlineMode: true))
        await #while(navigationController.children.count < 2)
        let playlistProcessor = try #require(subject.playlistProcessor as? PlaylistProcessor)
        #expect(playlistProcessor.state.offlineMode == true)
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
        subject.showPlaylist(state: nil)
        await #while(presentedViewController.children.count < 2)
        let playlistViewController = try #require(presentedViewController.children[1] as? PlaylistViewController)
        #expect(playlistViewController.navigationController != nil)
        // ok, this is it!
        subject.popPlaylist()
        await #while(presentedViewController.children.count > 1)
        #expect(playlistViewController.navigationController == nil)
    }

    @Test("showAlert presents an alert on the root view controller")
    func showAlert() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let pingProcessor = MockProcessor<PingAction, PingState, Void>()
        subject.pingProcessor = pingProcessor
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        // ok here we go
        subject.showAlert(title: "title", message: "message")
        await #while(rootViewController.presentedViewController == nil)
        let alert = try #require(rootViewController.presentedViewController as? UIAlertController)
        #expect(alert.title == "title")
        #expect(alert.message == "message")
        #expect(alert.actions.count == 1)
        #expect(alert.actions.first?.title == "OK")
        #expect(alert.preferredStyle == .alert)
    }

    @Test("showActionSheet presents an action sheet on the root view controller")
    func showActionSheet() async throws {
        // fake minimal initial interface
        let subject = RootCoordinator()
        let pingProcessor = MockProcessor<PingAction, PingState, Void>()
        subject.pingProcessor = pingProcessor
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        // ok here we go
        var result: String?
        Task {
            result = await subject.showActionSheet(title: "title", options: ["hey", "ho"])
        }
        await #while(rootViewController.presentedViewController == nil)
        let alert = try #require(rootViewController.presentedViewController as? UIAlertController)
        #expect(alert.title == "title")
        #expect(alert.actions.count == 3)
        #expect(alert.actions[0].title == "hey")
        #expect(alert.actions[1].title == "ho")
        #expect(alert.actions[2].title == "Cancel")
        #expect(alert.preferredStyle == .actionSheet)
        // test that `showActionSheet` returns the tapped button's title to the caller
        alert.tapButton(atIndex: 0)
        await #while(result == nil)
        #expect(result == "hey")
    }
}

@MainActor
class MockServerDelegate: ServerDelegate {
    var methodsCalled = [String]()
    var serverInfo: ServerInfo?
    func userEdited(serverInfo: ServerInfo) {
        methodsCalled.append(#function)
        self.serverInfo = serverInfo
    }
}
