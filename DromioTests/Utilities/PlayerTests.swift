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

    @Test("currentSongId: munges current item URL")
    func currentSongId() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        #expect(subject.currentSongId == "4")
    }

    @Test("adjustNowPlayingItemToCurrentItem: configured now playing info to match song")
    func adjust() {
        subject.knownSongs["4"] = SubsonicSong(
            id: "4",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 100
        )
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.adjustNowPlayingItemToCurrentItem()
        #expect(nowPlayingInfo.info[.title] as? String == "Title")
        #expect(nowPlayingInfo.info[.artist] as? String == "Artist")
        #expect(nowPlayingInfo.info[.duration] as? Int == 100)
    }

    @Test("play(url:song:) calls removeAllItems, calls insertAfter nil, sets category active, calls play, sets action to advance, adds to known songs")
    func play() {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil
        )
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(audioPlayer.methodsCalled == ["removeAllItems()", "insert(_:after:)", "play()"])
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.after == nil)
        #expect(audioPlayer.actionAtItemEnd == .advance)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("play(url:song:) configures now playing info")
    func playNowPlayingInfo() {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 100
        )
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(nowPlayingInfo.info[.title] as? String == "Title")
        #expect(nowPlayingInfo.info[.artist] as? String == "Artist")
        #expect(nowPlayingInfo.info[.time] as? Double == 0)
        #expect(nowPlayingInfo.info[.rate] as? Double == 1)
        #expect(nowPlayingInfo.info[.duration] as? Int == 100)
    }

    @Test("playNext(url:song:) calls insertAfter nil, adds to known songs")
    func playNext() {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil
        )
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
        #expect(audioSession.active == true)
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
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil
        )
        subject.knownSongs["1"] = song
        subject.clear()
        #expect(audioPlayer.methodsCalled == ["pause()", "removeAllItems()"])
        #expect(subject.knownSongs.isEmpty)
        #expect(nowPlayingInfo.methodsCalled == ["clear()"])
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == false)
    }

}
