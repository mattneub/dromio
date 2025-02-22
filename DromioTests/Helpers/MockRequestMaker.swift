@testable import Dromio

@MainActor
final class MockRequestMaker: RequestMakerType {
    var albumList = [SubsonicAlbum]()
    var songList = [SubsonicSong]()
    var albumId: String?
    var pingError: Error?
    var methodsCalled = [String]()

    func ping() async throws {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
    }

    func getAlbumList() async throws -> [SubsonicAlbum] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return albumList
    }

    func getSongsFor(albumId: String) async throws -> [SubsonicSong] {
        methodsCalled.append(#function)
        self.albumId = albumId
        if let pingError {
            throw pingError
        }
        return songList
    }

}
