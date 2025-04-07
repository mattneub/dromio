@testable import Dromio
import Foundation

@MainActor
final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var songList: [SubsonicSong]?
    var servers: [ServerInfo]?

    func saveCurrentPlaylist(songList: [SubsonicSong]) throws {
        methodsCalled.append(#function)
        self.songList = songList
    }
    
    func loadCurrentPlaylist() throws -> [SubsonicSong] {
        methodsCalled.append(#function)
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
