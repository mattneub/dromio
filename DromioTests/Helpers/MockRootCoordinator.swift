@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {
    var serverProcessor: (any Dromio.Processor<Dromio.ServerAction, Dromio.ServerState>)?

    var albumProcessor: (any Dromio.Processor<Dromio.AlbumAction, Dromio.AlbumState>)?
    var albumsProcessor: (any Dromio.Processor<Dromio.AlbumsAction, Dromio.AlbumsState>)?
    var playlistProcessor: (any Dromio.Processor<Dromio.PlaylistAction, Dromio.PlaylistState>)?

    var pingProcessor: (any Dromio.Processor<Dromio.PingAction, Dromio.PingState>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()
    var albumId: String?
    var songCount: Int?
    var title: String?

    func createInitialInterface(window: UIWindow) {
        methodsCalled.append(#function)
    }

    func showServer() {
        methodsCalled.append(#function)
    }

    func dismissServer() {
        methodsCalled.append(#function)
    }

    func showAlbums() {
        methodsCalled.append(#function)
    }

    func showAlbum(albumId: String, songCount: Int, title: String) {
        self.albumId = albumId
        self.songCount = songCount
        self.title = title
        methodsCalled.append(#function)
    }

    func showPlaylist() {
        methodsCalled.append(#function)
    }

    func popPlaylist() {
        methodsCalled.append(#function)
    }
}
