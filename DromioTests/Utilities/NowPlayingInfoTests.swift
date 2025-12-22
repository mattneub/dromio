@testable import Dromio
import Testing
import MediaPlayer

struct NowPlayingInfoTests {
    let subject = NowPlayingInfo()
    var center: MockNowPlayingInfoCenter!

    init() {
        let center = MockNowPlayingInfoCenter()
        subject.centerProvider = { center }
        self.center = center
    }

    @Test("center provider, by default, provides the real Now Playing Info Center")
    func centerProvider() {
        let subject = NowPlayingInfo()
        let product = subject.centerProvider()
        #expect(product === MPNowPlayingInfoCenter.default())
    }

    @Test("info: setting sets the corresponding properties in the now playing info")
    func info() {
        #expect(center.nowPlayingInfo == nil)
        subject.info[.title] = .string("Title")
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        var info = [NowPlayingInfoKey : NowPlayingInfoValue]()
        info[.artist] = .string("Artist")
        info[.duration] = .double(100)
        subject.info = info
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "Artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 100)
    }

    @Test("updateInfo batches incoming changes")
    func updateInfo() {
        #expect(center.nowPlayingInfo == nil)
        subject.info[.title] = .string("Title")
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        subject.updateInfo { info in
            info[.artist] = .string("Artist")
            info[.duration] = .double(100)
        }
        #expect(center.nowPlayingInfo?["title"] as? String == "Title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "Artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 100)
    }

    @Test("playing: sets the center's artist, title, duration, and id")
    func playingInfo() {
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.playing(song: song, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
    }

    @Test("playing: erases the center info first iff the id changes")
    func playingErasure() {
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        #expect(center.nowPlayingInfo == nil)
        subject.playing(song: song, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
        center.nowPlayingInfo?["dummy"] = "dummy"
        let song2 = SubsonicSong(id: "1", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.playing(song: song2, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] as? String == "dummy")
        let song3 = SubsonicSong(id: "2", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.playing(song: song3, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "2")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
    }

    @Test("playing: sets the center's time and rate")
    func playing() {
        #expect(center.nowPlayingInfo == nil)
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        subject.playing(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 1)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
    }

    @Test("playing: filters out duplicates")
    func playingDuplicates() {
        #expect(center.nowPlayingInfo == nil)
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        subject.playing(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 1)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
        center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] = 2.0
        center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] = 6.0
        subject.playing(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 2)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 6)
    }

    @Test("paused: sets the center's artist, title, duration, and id")
    func pausedInfo() {
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.paused(song: song, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
    }

    @Test("paused: erases the center info first iff the id changes")
    func pausedErasure() {
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: "artist", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        #expect(center.nowPlayingInfo == nil)
        subject.paused(song: song, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
        center.nowPlayingInfo?["dummy"] = "dummy"
        let song2 = SubsonicSong(id: "1", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.paused(song: song2, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "1")
        #expect(center.nowPlayingInfo?["dummy"] as? String == "dummy")
        let song3 = SubsonicSong(id: "2", title: "title2", album: nil, artist: "artist2", displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: 3, contributors: nil)
        subject.paused(song: song3, at: 1)
        #expect(center.nowPlayingInfo?["title"] as? String == "title2")
        #expect(center.nowPlayingInfo?["artist"] as? String == "artist2")
        #expect(center.nowPlayingInfo?["playbackDuration"] as? Double == 3)
        #expect(center.nowPlayingInfo?["mySecretIdentifier"] as? String == "2")
        #expect(center.nowPlayingInfo?["dummy"] == nil)
    }

    @Test("paused: sets the center's time and rate")
    func paused() {
        #expect(center.nowPlayingInfo == nil)
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        subject.paused(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 0)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
    }

    @Test("paused: filters out duplicates")
    func pausedDuplicates() {
        #expect(center.nowPlayingInfo == nil)
        let song = SubsonicSong(id: "1", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        subject.paused(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 0)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 3)
        center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] = 2.0
        center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] = 6.0
        subject.paused(song: song, at: 3)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyPlaybackRate"] as? Double == 2)
        #expect(center.nowPlayingInfo?["MPNowPlayingInfoPropertyElapsedPlaybackTime"] as? Double == 6)
    }

    @Test("clear: sets the now playing info to nil")
    func clear() {
        center.nowPlayingInfo = ["yoho": "howdy"]
        subject.clear()
        #expect(center.nowPlayingInfo == nil)
    }
}
