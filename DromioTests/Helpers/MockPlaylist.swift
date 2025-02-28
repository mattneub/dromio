@testable import Dromio
import Foundation

@MainActor
final class MockPlaylist: PlaylistType {
    var list = [SubsonicSong]()
    var methodsCalled = [String]()
    var errorToThrow: (any Error)?
    var sequenceToReturn = [SubsonicSong]()

    func append(_ song: Dromio.SubsonicSong) throws {
        methodsCalled.append(#function)
        if let error = errorToThrow {
            throw error
        }
        list.append(song)
    }

    func buildSequence(startingWith song: Dromio.SubsonicSong) -> [Dromio.SubsonicSong] {
        methodsCalled.append(#function)
        return sequenceToReturn
    }

    func clear() {
        methodsCalled.append(#function)
    }
}
