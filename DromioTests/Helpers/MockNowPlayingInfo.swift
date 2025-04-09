@testable import Dromio
import Testing
import Foundation

final class MockNowPlayingInfo: NowPlayingInfoType {

    var info = [NowPlayingInfoKey: Any]()
    var methodsCalled = [String]()
    var song: SubsonicSong?
    var time: Double?

    func playing(song: SubsonicSong, at time: TimeInterval) {
        methodsCalled.append(#function)
        self.time = time
        self.song = song
    }

    func paused(song: SubsonicSong, at time: TimeInterval) {
        methodsCalled.append(#function)
        self.time = time
        self.song = song
    }


    func clear() {
        methodsCalled.append(#function)
    }
}
