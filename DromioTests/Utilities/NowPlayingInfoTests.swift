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
        var info = [NowPlayingInfoKey : Any]()
        info[.artist] = "Artist"
        info[.duration] = 100
        subject.info = info
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "Artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Int == 100)
    }

    @Test("updateInfo batches incoming changes")
    func updateInfo() {
        #expect(center.nowPlayingInfo == nil)
        subject.info[.title] = "Title"
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        subject.updateInfo { info in
            info[.artist] = "Artist"
            info[.duration] = 100
        }
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "Artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Int == 100)
    }

    @Test("display: sets the center's artist, title, duration, and id")
    func display() {
        subject.display(song: SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil))
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyExternalContentIdentifier"] as? String == "1")
    }

    @Test("display: erases the center info first iff the id changes")
    func displayErasure() {
        #expect(center.nowPlayingInfo == nil)
        subject.display(song: SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil))
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyExternalContentIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
        center.nowPlayingInfo?["dummy"] = "dummy"
        subject.display(song: SubsonicSong(id: "1", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil))
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyExternalContentIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] as? String == "dummy")
        subject.display(song: SubsonicSong(id: "2", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil))
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyExternalContentIdentifier"] as? String == "2")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
    }

    @Test("playingAt: sets the center's time and rate")
    func playing() {
        #expect(center.nowPlayingInfo == nil)
        subject.playingAt(3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 1)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
    }

    @Test("pausedAt: sets the center's time and rate")
    func paused() {
        #expect(center.nowPlayingInfo == nil)
        subject.pausedAt(3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 0)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
    }

    @Test("clear: sets the now playing info to nil")
    func clear() {
        center.nowPlayingInfo = ["yoho": "howdy"]
        subject.clear()
        #expect(center.nowPlayingInfo == nil)
    }
}
