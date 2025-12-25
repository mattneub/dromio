@testable import Dromio
import Foundation

final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var songList: [SubsonicSong]?
    var servers: [ServerInfo]?
    var currentFolder: SubsonicFolder?
    var suppressName: Bool?
    var currentFolderId: Int?
    var currentFolderName: String?

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

    func save(currentFolder: SubsonicFolder?, suppressName: Bool) {
        methodsCalled.append(#function)
        self.currentFolder = currentFolder
        self.suppressName = suppressName
    }

    func loadCurrentFolder() -> Int? {
        methodsCalled.append(#function)
        return self.currentFolderId
    }

    func loadCurrentFolderName() -> String? {
        methodsCalled.append(#function)
        return self.currentFolderName
    }
}
