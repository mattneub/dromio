@testable import Dromio
import Foundation

@MainActor
final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var songList: [SubsonicSong]?
    var key: PersistenceKey?

    func save(songList: [Dromio.SubsonicSong], key: PersistenceKey) throws {
        methodsCalled.append(#function)
        self.songList = songList
        self.key = key
    }
    
    func loadSongList(key: PersistenceKey) throws -> [Dromio.SubsonicSong] {
        methodsCalled.append(#function)
        self.key = key
        return songList ?? []
    }
}
