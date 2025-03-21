@testable import Dromio
import Testing
import AVFoundation
import MediaPlayer
import WaitWhile

@MainActor
struct PlayerTests {
    var subject: Player!
    let audioPlayer = MockQueuePlayer()
    let audioSession = MockAudioSession()
    let nowPlayingInfo = MockNowPlayingInfo()

    init() {
        subject = Player(player: audioPlayer)
        services.audioSession = audioSession
        services.nowPlayingInfo = nowPlayingInfo
        services.player = MockPlayer() // because otherwise two players exists, messing up our notification/observation tests
    }

    @Test("currentSongId: munges current item URL when it is a file URL")
    func currentSongIdFile() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        #expect(subject.currentSongId == "4")
    }

    @Test("currentSongId: munges current item URL when it is a streaming http(s) URL")
    func currentSongIdStreaming() async throws {
        // use the _real_ URLMaker and the _real_ request maker to form a stream URL
        services.urlMaker = URLMaker()
        services.requestMaker = RequestMaker()
        services.urlMaker.currentServerInfo = try .init(scheme: "http", host: "example.com", port: "1", username: "user", password: "pass")
        let url = try await services.requestMaker.stream(songId: "4")
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: url))
        #expect(subject.currentSongId == "4")
    }

    @Test("adjustNowPlayingItemToCurrentItem: calls now playing info `display`, sets currentSongIdPublisher")
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
            duration: 100,
            contributors: nil
        )
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.adjustNowPlayingItemToCurrentItem()
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)"])
        #expect(nowPlayingInfo.song == subject.knownSongs["4"]!)
        #expect(subject.currentSongIdPublisher.value == "4")
    }

    @Test("adjustNowPlayingItemToCurrentItem: if current item is nil, calls clear, deactivates session, sets currentSongIdPublisher")
    func adjustNil() {
        audioPlayer.currentItem = nil
        subject.adjustNowPlayingItemToCurrentItem()
        #expect(nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(audioSession.methodsCalled.contains("setActive(_:options:)"))
        #expect(audioSession.active == false)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("if the queue player changes current item, call now playing info display, sets currentSongIdPublisher")
    func adjustWhenCurrentItemChanges() async {
        let subject = Player(player: AVQueuePlayer())
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
            duration: 100,
            contributors: nil
        )
        let item = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.player.insert(item, after: nil)
        subject.player.play()
        await #while(nowPlayingInfo.song == nil)
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)"])
        #expect(nowPlayingInfo.song == subject.knownSongs["4"]!)
        #expect(subject.currentSongIdPublisher.value == "4")
    }

    @Test("if the queue player changes current item to nil, calls clear, deactivates session, sets currentSongIdPublisher")
    func adjustNilWhenCurrentItemChanges() async {
        let subject = Player(player: AVQueuePlayer())
        let item = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.player.insert(item, after: nil)
        subject.player.removeAllItems()
        await #while(nowPlayingInfo.info[.title] != nil)
        await #while(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(audioSession.methodsCalled.contains("setActive(_:options:)"))
        #expect(audioSession.active == false)
        #expect(subject.currentSongIdPublisher.value == nil)
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
            duration: nil,
            contributors: nil
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

    @Test("play(url:song:) configures now playing info, sets current item publisher")
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
            duration: 100,
            contributors: nil
        )
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)", "playingAt(_:)"])
        #expect(nowPlayingInfo.song == song)
        #expect(nowPlayingInfo.time == 0)
        #expect(subject.currentSongIdPublisher.value == "1")
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
            duration: nil,
            contributors: nil
        )
        let url = URL(string: "http://example.com")!
        subject.playNext(url: url, song: song)
        #expect(audioPlayer.methodsCalled == ["insert(_:after:)"])
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(audioPlayer.after == nil)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("doPlay: activates audio session, calls play, tells now playing info playing at current time")
    func doPlay() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        subject.doPlay()
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.contains("playingAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
    }

    @Test("doPause: calls pause, tell now playing info paused at current time")
    func doPause() {
        audioPlayer.time = 30
        subject.doPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
        #expect(nowPlayingInfo.methodsCalled.contains("pausedAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
    }

    @Test("primeThePump: if we are paused, tells now playing info to display song, play, and pause")
    func primeThePump() {
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 0
        subject.primeThePump()
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)", "playingAt(_:)", "pausedAt(_:)"])
        #expect(nowPlayingInfo.time == 30)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled == ["play()", "currentTime()", "pause()", "currentTime()"])
        #expect(subject.currentSongIdPublisher.value == "1")
    }

    @Test("primeThePump: if we are not paused, none of that happens")
    func primeThePumpNotPaused() {
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 1
        subject.primeThePump()
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("primeThePump: if we are paused but no current item, none of that happens")
    func primeThePumpNoCurrentItem() {
        audioPlayer.currentItem = nil
        audioPlayer.time = 30
        audioPlayer.rate = 0
        subject.primeThePump()
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("interruption ended is just like primeThePump() [because it calls it]")
    func interruptionEnded() {
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 0
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ])
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)", "playingAt(_:)", "pausedAt(_:)"])
        #expect(nowPlayingInfo.time == 30)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled == ["play()", "currentTime()", "pause()", "currentTime()"])
        #expect(subject.currentSongIdPublisher.value == "1")
    }

    @Test("interruption started does nothing")
    func interruptionStarted() {
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 0
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ])
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("interruption ended does nothing if not paused")
    func interruptionEndedNotPaused() {
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 1
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ])
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("interruption ended does nothing if nil current item")
    func interruptionEndedNilCurrentItem() {
        audioPlayer.currentItem = nil
        audioPlayer.time = 30
        audioPlayer.rate = 0
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ])
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

    @Test("clear: call pause and removeAllItems, empties the known list, nilifies currentSongIdPublisher")
    func clear() {
        subject.currentSongIdPublisher.value = "10"
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
            duration: nil,
            contributors: nil
        )
        subject.knownSongs["1"] = song
        subject.clear()
        #expect(audioPlayer.methodsCalled == ["pause()", "removeAllItems()"])
        #expect(subject.knownSongs.isEmpty)
        #expect(nowPlayingInfo.methodsCalled == ["clear()"])
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == false)
        #expect(subject.currentSongIdPublisher.value == nil)
    }

}
