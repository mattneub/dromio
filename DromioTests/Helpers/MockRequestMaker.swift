@testable import Dromio
import Foundation

@MainActor
final class MockRequestMaker: RequestMakerType {
    var albumList = [SubsonicAlbum]()
    var songList = [SubsonicSong]()
    var albumId: String?
    var songId: String?
    var pingError: Error?
    var methodsCalled = [String]()
    var url = URL(string: "http://example.com")!

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

    func download(songId: String) async throws -> URL {
        methodsCalled.append(#function)
        self.songId = songId
        if let pingError {
            throw pingError
        }
        return url
    }
}
