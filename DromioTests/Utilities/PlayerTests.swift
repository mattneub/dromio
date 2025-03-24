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

    @Test("currentSong: gets song via currentSongId from the known songs")
    func currentSong() async throws {
        let song = SubsonicSong(
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
        subject.knownSongs["4"] = song
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        #expect(subject.currentSong == song)
        subject.knownSongs["4"] = nil
        #expect(subject.currentSong == nil)
        subject.knownSongs["4"] = song
        audioPlayer.currentItem = nil
        #expect(subject.currentSong == nil)
    }

    @Test("if the queue player changes current item, calls now playing info `display` and `paused`, sets currentSongIdPublisher, activates")
    func itemChanges() async {
        let subject = Player(player: AVQueuePlayer()) // real player!
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
        let url = Bundle(for: MockPlayer.self).url(forResource: "4", withExtension: "mp3")! // real song!
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        subject.player.insert(item, after: nil)
        subject.player.play()
        try? await Task.sleep(for: .seconds(0.1)) // give it a chance to start, then test
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)", "playingAt(_:)"])
        #expect(nowPlayingInfo.song == subject.knownSongs["4"]!)
        #expect(subject.currentSongIdPublisher.value == "4")
        #expect(audioSession.methodsCalled.contains("setActive(_:options:)"))
        #expect(audioSession.active == true)
    }

    @Test("if the queue player changes current item to nil, calls clear, deactivates session, sets playerState and currentSongIdPublisher")
    func itemChangesToNil() async {
        let subject = Player(player: AVQueuePlayer()) // real player!
        subject.playerStatePublisher.value = .playing
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
        let url = Bundle(for: MockPlayer.self).url(forResource: "4", withExtension: "mp3")! // real song!
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        subject.player.insert(item, after: nil)
        subject.player.play() // play the whole thing so it ends in good order
        await #while(!nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(audioSession.methodsCalled.contains("setActive(_:options:)"))
        #expect(audioSession.active == false)
        #expect(subject.currentSongIdPublisher.value == nil)
        #expect(subject.playerStatePublisher.value == .empty)
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
        #expect(audioPlayer.methodsCalled == ["removeAllItems()", "insert(_:after:)", "play()", "currentTime()"])
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("play(url:song:) configures now playing info, sets player state and current item publisher")
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
        audioPlayer.time = 10
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        subject.play(url: url, song: song)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(nowPlayingInfo.methodsCalled == ["display(song:)", "playingAt(_:)"])
        #expect(nowPlayingInfo.song == song)
        #expect(nowPlayingInfo.time == 10)
        #expect(subject.currentSongIdPublisher.value == "1")
        #expect(subject.playerStatePublisher.value == .playing)
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
        subject.doPlay(updateOnly: false)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.contains("playingAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
        #expect(subject.playerStatePublisher.value == .playing)
    }

    @Test("doPlay: if update only true, activates audio session, doesn't call play, tells now playing info playing at current time")
    func doPlayUpdateOnlyTrue() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 1
        subject.doPlay(updateOnly: true) // *
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.contains("playingAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
        #expect(subject.playerStatePublisher.value == .playing)
    }

    @Test("doPlay: when paused if update only true, activates audio session, doesn't call play, tells now playing info paused at current time")
    func doPlayUpdateOnlyTruePaused() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 0 // *
        subject.doPlay(updateOnly: true)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.contains("pausedAt(_:)")) // *
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
        #expect(subject.playerStatePublisher.value == .paused)
    }

    @Test("doPause: calls pause, tell now playing info paused at current time, sends player state")
    func doPause() {
        audioPlayer.time = 30
        subject.doPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
        #expect(nowPlayingInfo.methodsCalled.contains("pausedAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.playerStatePublisher.value == .paused)
    }

    @Test("playPause is like doPlay if rate is 0")
    func playPause() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 0
        subject.playPause()
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.contains("playingAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
    }

    @Test("playPause is like doPause if rate is 1")
    func playPauseRate1() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 1
        subject.playPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
        #expect(nowPlayingInfo.methodsCalled.contains("pausedAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
    }

    @Test("interruptionEnded: if we are playing, nothing happens")
    func interruptionEndedRate1() {
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
    }

    @Test("interruptionEnded if we are paused, doPlay followed by doPause")
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
        #expect(audioSession.methodsCalled == ["setActive(_:options:)", "setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(audioPlayer.methodsCalled == ["play()", "currentTime()", "pause()", "currentTime()"])
        #expect(subject.currentSongIdPublisher.value == "1")
        #expect(subject.playerStatePublisher.value == .paused)
    }

    @Test("clear: call pause and removeAllItems, empties the known list, nilifies currentSongIdPublisher")
    func clear() {
        subject.currentSongIdPublisher.value = "10"
        subject.playerStatePublisher.value = .playing
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
        #expect(subject.playerStatePublisher.value == .empty)
    }

    @Test("backgrounding: if rate is 0, sets audioSession inactive")
    func backgrounding() {
        audioPlayer.rate = 0
        audioSession.active = true
        subject.backgrounding()
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == false)
    }

    @Test("backgrounding: if rate is 1, does nothing")
    func backgroundingRate1() {
        audioPlayer.rate = 1
        subject.backgrounding()
        #expect(audioSession.methodsCalled.isEmpty)
    }

    @Test("foregrounding: if rate is 1, just like doPlay")
    func foregroundingRate() {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        audioPlayer.time = 30
        audioPlayer.rate = 1
        subject.foregrounding()
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioSession.active == true)
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.contains("playingAt(_:)"))
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher.value == "4")
        #expect(subject.playerStatePublisher.value == .playing)
    }

    @Test("foregrounding: if rate is 0, does nothing")
    func foregroundingRate0() {
        audioPlayer.rate = 0
        subject.foregrounding()
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(audioSession.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.playerStatePublisher.value == .empty)
    }
}
