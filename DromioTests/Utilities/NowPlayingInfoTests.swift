@testable import Dromio
import Testing
import MediaPlayer

@MainActor
struct NowPlayingInfoTests {
    let subject = NowPlayingInfo()
    let center = MockNowPlayingInfoCenter()

    init() {
        subject.center = center
    }

    @Test("info: setting sets the corresponding properties in the now playing info")
    func info() {
        #expect(center.nowPlayingInfo == nil)
        subject.info[.title] = "Title"
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        var info = subject.info
        info[.artist] = "Artist"
        info[.duration] = 100
        subject.info = info
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "Artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Int == 100)
    }

    @Test("clear: sets the now playing info to nil")
    func clear() {
        center.nowPlayingInfo = ["yoho": "howdy"]
        subject.clear()
        #expect(center.nowPlayingInfo == nil)
    }
}
