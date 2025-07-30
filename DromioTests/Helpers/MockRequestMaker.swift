@testable import Dromio
import Foundation

@MainActor
final class MockRequestMaker: RequestMakerType {
    var albumList = [SubsonicAlbum]()
    var artistList = [SubsonicArtist]()
    var folderList = [SubsonicFolder(id: 1, name: "Music Folder")]
    var songList = [SubsonicSong]()
    var albumId: String?
    var songId: String?
    var artistId: String?
    var user: SubsonicUser?
    var pingError: Error?
    var query: String?
    var methodsCalled = [String]()
    var streamURL = URL(string: "http://example.com")!
    var downloadURL = URL(string: "file://tempFolder/stuff")!
    var actions = [JukeboxAction]()
    var songIds = [String?]()

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
