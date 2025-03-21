@testable import Dromio
import Testing
import Foundation

final class MockNowPlayingInfo: NowPlayingInfoType {

    var info = [NowPlayingInfoKey: Any]()
    var methodsCalled = [String]()
    var song: SubsonicSong?
    var time: Double?

    func display(song: SubsonicSong) {
        methodsCalled.append(#function)
        self.song = song
    }

    func playingAt(_ time: TimeInterval) {
        methodsCalled.append(#function)
        self.time = time
    }

    func pausedAt(_ time: TimeInterval) {
        methodsCalled.append(#function)
        self.time = time
    }


    func clear() {
        methodsCalled.append(#function)
    }
}
