@testable import Dromio
import Testing

@MainActor
struct PlaylistStateTests {
    @Test("logic of show playpause is correct")
    func showPlayPause() {
        var subject = PlaylistState()
        subject.jukeboxMode = false
        subject.currentSongId = nil
        #expect(subject.showPlayPauseButton == false)
        subject.jukeboxMode = true
        subject.currentSongId = nil
        #expect(subject.showPlayPauseButton == false)
        subject.jukeboxMode = false
        subject.currentSongId = "1"
        #expect(subject.showPlayPauseButton == true)
        subject.jukeboxMode = true
        subject.currentSongId = "1"
        #expect(subject.showPlayPauseButton == false)
    }
}
