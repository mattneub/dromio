@testable import Dromio
import UIKit

@MainActor
final class MockRootCoordinator: RootCoordinatorType {
    var serverProcessor: (any AsyncProcessor<ServerAction, ServerState, Void>)?
    var albumProcessor: (any AsyncProcessor<AlbumAction, AlbumState, AlbumEffect>)?
    var albumsProcessor: (any AsyncProcessor<AlbumsAction, AlbumsState, AlbumsEffect>)?
    var artistsProcessor: (any AsyncProcessor<ArtistsAction, ArtistsState, ArtistsEffect>)?
    var playlistProcessor: (any AsyncProcessor<PlaylistAction, PlaylistState, PlaylistEffect>)?
    var artistAlbumsProcessor: (any AsyncProcessor<AlbumsAction, AlbumsState, AlbumsEffect>)?
    var pingProcessor: (any AsyncProcessor<PingAction, PingState, Void>)?
    var rootViewController: UIViewController?
    var methodsCalled = [String]()
    var albumId: String?
    var title: String?
    var message: String?
    var options = [String]()
    var optionToReturn: String?
    var albumsState: AlbumsState?
    var playlistState: PlaylistState?
    var delegate: (any ServerDelegate)?

    func createInitialInterface(window: UIWindow) {
        methodsCalled.append(#function)
    }

    func showServer(delegate: any ServerDelegate) {
        methodsCalled.append(#function)
        self.delegate = delegate
    }

    func dismissToPing() {
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

    func showPlaylist(state: PlaylistState?) {
        methodsCalled.append(#function)
        self.playlistState = state
    }

    func popPlaylist() {
        methodsCalled.append(#function)
    }

    func showAlert(title: String?, message: String?) {
        methodsCalled.append(#function)
        self.title = title
        self.message = message
    }

    func showActionSheet(title: String, options: [String]) async -> String? {
        methodsCalled.append(#function)
        self.title = title
        self.options = options
        return optionToReturn
    }

}
