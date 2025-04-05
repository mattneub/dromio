@testable import Dromio
import Foundation

@MainActor
final class MockPlaylist: PlaylistType {
    var list = [SubsonicSong]()
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?
    var song: SubsonicSong?
    var fromRow: Int?
    var toRow: Int?

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
