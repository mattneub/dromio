@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {

    var serverProcessor: (any Processor<ServerAction, ServerState>)?

    var albumProcessor: (any Processor<AlbumAction, AlbumState>)?
    var albumsProcessor: (any Processor<AlbumsAction, AlbumsState>)?
    var artistsProcessor: (any Processor<ArtistsAction, ArtistsState>)?
    var playlistProcessor: (any Processor<PlaylistAction, PlaylistState>)?
    var artistAlbumsProcessor: (any Dromio.Processor<Dromio.AlbumsAction, Dromio.AlbumsState>)?

    var pingProcessor: (any Processor<PingAction, PingState>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()
    var albumId: String?
    var title: String?
    var albumsState: AlbumsState?

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

    func showAlbum(albumId: String, title: String) {
        self.albumId = albumId
        self.title = title
        methodsCalled.append(#function)
    }

    func showArtists() {
        methodsCalled.append(#function)
    }

    func dismissArtists() {
        methodsCalled.append(#function)
    }

    func showAlbumsForArtist(state: AlbumsState) {
        methodsCalled.append(#function)
        albumsState = state
    }

    func showPlaylist() {
        methodsCalled.append(#function)
    }

    func popPlaylist() {
        methodsCalled.append(#function)
    }
}
