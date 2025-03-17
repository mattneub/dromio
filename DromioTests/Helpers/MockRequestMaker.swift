@testable import Dromio
import Foundation

@MainActor
final class MockRequestMaker: RequestMakerType {
    var albumList = [SubsonicAlbum]()
    var artistList = [SubsonicArtist]()
    var songList = [SubsonicSong]()
    var albumId: String?
    var songId: String?
    var artistId: String?
    var user: SubsonicUser?
    var pingError: Error?
    var query: String?
    var methodsCalled = [String]()
    var url = URL(string: "http://example.com")!

    func ping() async throws {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
    }

    func getUser() async throws -> SubsonicUser {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        guard let user else { fatalError("You forgot to provide a `user`.") }
        return user
    }

    func getAlbumList() async throws -> [SubsonicAlbum] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return albumList
    }

    func getAlbumsRandom() async throws -> [SubsonicAlbum] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return albumList
    }

    func getArtists() async throws -> [SubsonicArtist] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return artistList
    }

    func getArtistsBySearch() async throws -> [SubsonicArtist] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return artistList
    }

    func getSongsBySearch(query: String) async throws -> [SubsonicSong] {
        methodsCalled.append(#function)
        self.query = query
        if let pingError {
            throw pingError
        }
        return songList
    }

    func getAlbumsFor(artistId: String) async throws -> [SubsonicAlbum] {
        methodsCalled.append(#function)
        self.artistId = artistId
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

    func stream(songId: String) async throws -> URL {
        methodsCalled.append(#function)
        self.songId = songId
        if let pingError {
            throw pingError
        }
        return url
    }

    func jukebox(additional: KeyValuePairs<String, String>) async throws -> Dromio.JukeboxStatus? {
        methodsCalled.append(#function)
        return nil
    }

}
