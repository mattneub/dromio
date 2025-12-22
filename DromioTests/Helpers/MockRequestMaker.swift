@testable import Dromio
import Foundation

final class MockRequestMaker: RequestMakerType {
    nonisolated(unsafe) var albumList = [SubsonicAlbum]()
    nonisolated(unsafe) var artistList = [SubsonicArtist]()
    nonisolated(unsafe) var folderList = [SubsonicFolder]()
    nonisolated(unsafe) var songList = [SubsonicSong]()
    nonisolated(unsafe) var albumId: String?
    nonisolated(unsafe) var songId: String?
    nonisolated(unsafe) var artistId: String?
    nonisolated(unsafe) var user: SubsonicUser?
    nonisolated(unsafe) var pingError: Error?
    nonisolated(unsafe) var query: String?
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var streamURL = URL(string: "http://example.com")!
    nonisolated(unsafe) var downloadURL = URL(string: "file://tempFolder/stuff")!
    nonisolated(unsafe) var actions = [JukeboxAction]()
    nonisolated(unsafe) var songIds = [String?]()

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

    func getFolders() async throws -> [SubsonicFolder] {
        methodsCalled.append(#function)
        if let pingError {
            throw pingError
        }
        return folderList
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
        return downloadURL
    }

    func stream(songId: String) async throws -> URL {
        methodsCalled.append(#function)
        self.songId = songId
        if let pingError {
            throw pingError
        }
        return streamURL
    }

    func jukebox(action: JukeboxAction, songId: String?) async throws -> JukeboxStatus? {
        methodsCalled.append(#function)
        actions.append(action)
        songIds.append(songId)
        return nil
    }

    func scrobble(songId: String) async throws {
        methodsCalled.append(#function)
        self.songId = songId
    }

}
