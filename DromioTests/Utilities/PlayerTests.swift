@testable import Dromio
import Testing
import AVFoundation
import MediaPlayer

@MainActor
struct PlayerTests {
    let subject = Player()
    let audioSession = MockAudioSession()
    let audioPlayer = MockQueuePlayer()
    let nowPlayingInfo = MockNowPlayingInfo()

    init() {
        subject.player = audioPlayer
        services.audioSession = audioSession
        services.nowPlayingInfo = nowPlayingInfo
    }

    @Test("play(url:song:) calls removeAllItems, calls insertAfter nil, sets category active, calls play, sets action to advance, adds to known songs")
    func play() {
        let song = SubsonicSong(id: "1", title: "title", artist: "artist", track: 1, albumId: nil, suffix: nil, duration: nil)
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(audioPlayer.methodsCalled == ["removeAllItems()", "insert(_:after:)", "play()"])
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioPlayer.after == nil)
        #expect(audioPlayer.actionAtItemEnd == .advance)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("play(url:song:) configures now playing info")
    func playNowPlayingInfo() {
        let song = SubsonicSong(id: "1", title: "title", artist: "artist", track: 1, albumId: nil, suffix: nil, duration: 100)
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(nowPlayingInfo.info[.title] as? String == "title")
        #expect(nowPlayingInfo.info[.artist] as? String == "artist")
        #expect(nowPlayingInfo.info[.time] as? Double == 0)
        #expect(nowPlayingInfo.info[.rate] as? Double == 1)
        #expect(nowPlayingInfo.info[.duration] as? Int == 100)
    }

    @Test("playNext(url:song:) calls insertAfter nil, adds to known songs")
    func playNext() {
        let song = SubsonicSong(id: "1", title: "title", artist: "artist", track: 1, albumId: nil, suffix: nil, duration: nil)
        let url = URL(string: "http://example.com")!
        subject.playNext(url: url, song: song)
        #expect(audioPlayer.methodsCalled == ["insert(_:after:)"])
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(audioPlayer.after == nil)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("doPlay: activates audio session, calls play, configures now playing info")
    func doPlay() {
        audioPlayer.time = 30
        subject.doPlay()
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.info[.time] as? Double == 30)
        #expect(nowPlayingInfo.info[.rate] as? Double == 1)
    }

    @Test("doPause: calls pause, configures now playing info")
    func doPause() {
        audioPlayer.time = 30
        subject.doPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
        #expect(nowPlayingInfo.info[.time] as? Double == 30)
        #expect(nowPlayingInfo.info[.rate] as? Double == 0)
    }

    @Test("clear: call pause and removeAllItems, empties the known list")
    func clear() {
        let song = SubsonicSong(id: "1", title: "title", artist: "artist", track: 1, albumId: nil, suffix: nil, duration: nil)
        subject.knownSongs["1"] = song
        subject.clear()
        #expect(audioPlayer.methodsCalled == ["pause()", "removeAllItems()"])
        #expect(subject.knownSongs.isEmpty)
    }

}
