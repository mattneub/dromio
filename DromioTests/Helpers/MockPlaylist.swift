@testable import Dromio
import Foundation

final class MockPlaylist: PlaylistType {
    nonisolated(unsafe) var list = [SubsonicSong]()
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var errorToThrow: (any Error)?
    nonisolated(unsafe) var song: SubsonicSong?
    nonisolated(unsafe) var fromRow: Int?
    nonisolated(unsafe) var toRow: Int?

    func append(_ song: SubsonicSong) throws {
        methodsCalled.append(#function)
        if let error = errorToThrow {
            throw error
        }
        list.append(song)
    }

    func setList(_ songs: [SubsonicSong]) {
        methodsCalled.append(#function)
        self.list = songs
    }

    func delete(song: SubsonicSong) {
        methodsCalled.append(#function)
        self.song = song
    }

    func move(from fromRow: Int, to toRow: Int) {
        methodsCalled.append(#function)
        self.fromRow = fromRow
        self.toRow = toRow
    }

    func clear() {
        methodsCalled.append(#function)
    }
}
