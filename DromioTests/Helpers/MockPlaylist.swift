@testable import Dromio
import Foundation

@MainActor
final class MockPlaylist: PlaylistType {
    var list = [SubsonicSong]()
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?
    var song: SubsonicSong?

    func append(_ song: SubsonicSong) throws {
        methodsCalled.append(#function)
        if let error = errorToThrow {
            throw error
        }
        list.append(song)
    }

    func delete(song: Dromio.SubsonicSong) {
        methodsCalled.append(#function)
        self.song = song
    }

    func clear() {
        methodsCalled.append(#function)
    }
}
