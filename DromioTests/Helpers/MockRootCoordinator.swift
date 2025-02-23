@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {
    var albumProcessor: (any Dromio.Processor<Dromio.AlbumAction, Dromio.AlbumState>)?
    var albumsProcessor: (any Dromio.Processor<Dromio.AlbumsAction, Dromio.AlbumsState>)?
    var playlistProcessor: (any Dromio.Processor<Dromio.PlaylistAction, Dromio.PlaylistState>)?

    var pingProcessor: (any Dromio.Processor<Dromio.PingAction, Dromio.PingState>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()
    var albumId: String?

    func createInitialInterface(window: UIWindow) {
        methodsCalled.append(#function)
    }

    func showAlbums() {
        methodsCalled.append(#function)
    }

    func showAlbum(albumId: String) {
        self.albumId = albumId
        methodsCalled.append(#function)
    }

    func showPlaylist() {
        methodsCalled.append(#function)
    }
}
