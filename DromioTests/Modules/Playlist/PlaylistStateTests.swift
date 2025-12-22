@testable import Dromio
import Testing

struct PlaylistStateTests {
    @Test("logic of showClearAndJukebox is correct")
    func showClearAndJukebox() {
        var subject = PlaylistState()
        subject.offlineMode = false
        #expect(subject.showClearButtonAndJukeboxButton == true)
        subject.offlineMode = true
        #expect(subject.showClearButtonAndJukeboxButton == false)
        subject.editMode = true
        subject.offlineMode = false
        #expect(subject.showClearButtonAndJukeboxButton == false)
        subject.offlineMode = true
        #expect(subject.showClearButtonAndJukeboxButton == false)
    }

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
        subject.editMode = true
        subject.jukeboxMode = false
        subject.currentSongId = nil
        #expect(subject.showPlayPauseButton == false)
        subject.jukeboxMode = true
        subject.currentSongId = nil
        #expect(subject.showPlayPauseButton == false)
        subject.jukeboxMode = false
        subject.currentSongId = "1"
        #expect(subject.showPlayPauseButton == false)
        subject.jukeboxMode = true
        subject.currentSongId = "1"
        #expect(subject.showPlayPauseButton == false)
    }
}
