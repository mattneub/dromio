@testable import Dromio
import Foundation

@MainActor
final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var songList: [SubsonicSong]?
    var servers: [ServerInfo]?
    var key: PersistenceKey?

    func save(songList: [SubsonicSong], key: PersistenceKey) throws {
        methodsCalled.append(#function)
        self.songList = songList
        self.key = key
    }
    
    func loadSongList(key: PersistenceKey) throws -> [SubsonicSong] {
        methodsCalled.append(#function)
        self.key = key
        return songList ?? []
    }

    func save(servers: [ServerInfo]) throws {
        methodsCalled.append(#function)
        self.servers = servers
    }

    func loadServers() throws -> [ServerInfo] {
        methodsCalled.append(#function)
        return self.servers ?? []
    }

}
