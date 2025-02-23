@testable import Dromio
import Foundation

@MainActor
final class MockPlaylist: PlaylistType {
    var list = [SubsonicSong]()
    var methodsCalled = [String]()

    func append(_ song: Dromio.SubsonicSong) {
        methodsCalled.append(#function)
        list.append(song)
    }
}
