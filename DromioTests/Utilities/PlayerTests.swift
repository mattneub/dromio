@testable import Dromio
import Testing
import AVFoundation
import MediaPlayer
import WaitWhile

struct PlayerTests {
    var subject: Player!
    let audioPlayer = MockQueuePlayer()
    let nowPlayingInfo = MockNowPlayingInfo()
    var commandCenter: MockRemoteCommandCenter!
    let trampoline = MockPlayerTrampoline()
    let audioSessionActor = MockAudioSessionActor()

    init() {
        let commandCenter = MockRemoteCommandCenter()
        subject = Player(
            player: audioPlayer,
            commandCenterProvider: { commandCenter },
            trampoline: trampoline,
            audioSessionActor: audioSessionActor
        )
        self.commandCenter = commandCenter
        services.nowPlayingInfo = nowPlayingInfo
        services.player = MockPlayer() // because otherwise two players exists, messing up our notification/observation tests
    }

    @Test("default configuration has an AVQueuePlayer and provides the remote command center")
    func defaultConfig() {
        let subject = Player()
        #expect(subject.player is AVQueuePlayer)
        let center = subject.commandCenterProvider()
        #expect(center === MPRemoteCommandCenter.shared())
    }

    @Test("initializer: sets up remote command center, deinit: tears it down")
    func initializer() async throws {
        let commandCenter = MockRemoteCommandCenter()
        var subject: Player? = Player(player: audioPlayer, commandCenterProvider: { commandCenter })
        #expect(subject!.trampoline is PlayerTrampoline)
        #expect(subject!.trampoline.player === subject!)
        //
        let play = try #require(commandCenter.play as? MockCommand)
        #expect(play.methodsCalled.contains("addTarget(_:action:)"))
        #expect(play.target === subject!.trampoline)
        #expect(play.action == #selector(trampoline.doPlay(_:)))
        //
        let pause = try #require(commandCenter.pause as? MockCommand)
        #expect(pause.methodsCalled.contains("addTarget(_:action:)"))
        #expect(pause.target === subject!.trampoline)
        #expect(pause.action == #selector(trampoline.doPause(_:)))
        //
        let skipForward = try #require(commandCenter.skipForward as? MockSkipCommand)
        #expect(skipForward.methodsCalled.contains("addTarget(_:action:)"))
        #expect(skipForward.target === subject!.trampoline)
        #expect(skipForward.action == #selector(trampoline.doSkipForward(_:)))
        #expect(skipForward.methodsCalled.contains("setInterval(_:)"))
        #expect(skipForward.interval == 30)
        //
        let skipBack = try #require(commandCenter.skipBack as? MockSkipCommand)
        #expect(skipBack.methodsCalled.contains("addTarget(_:action:)"))
        #expect(skipBack.target === subject!.trampoline)
        #expect(skipBack.action == #selector(trampoline.doSkipBack(_:)))
        #expect(skipBack.methodsCalled.contains("setInterval(_:)"))
        #expect(skipBack.interval == 30)
        //
        let change = try #require(commandCenter.changePlaybackPosition as? MockCommand)
        #expect(change.isEnabled == false)
        //
        subject = nil
        await #while(!play.methodsCalled.contains("removeTarget(_:)"))
        #expect(play.methodsCalled.contains("removeTarget(_:)"))
        #expect(pause.methodsCalled.contains("removeTarget(_:)"))
        #expect(skipForward.methodsCalled.contains("removeTarget(_:)"))
        #expect(skipBack.methodsCalled.contains("removeTarget(_:)"))
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

    @Test("if the queue player changes current item, calls now playing info `playing`, sets playerState and currentSongIdPublisher, activates")
    func itemChanges() async {
        subject.playerStatePublisher = .empty
        let subject = Player(
            player: AVQueuePlayer(), // real player!
            commandCenterProvider: { commandCenter },
            trampoline: trampoline,
            audioSessionActor: audioSessionActor
        )
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
        let url = #bundle.url(forResource: "4", withExtension: "mp3")! // real song!
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        subject.player.insert(item, after: nil)
        subject.player.play()
        await #while(subject.currentSongIdPublisher != "4")
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.song == subject.knownSongs["4"]!)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(await audioSessionActor.methodsCalled.contains("activate(options:)"))
        #expect(await audioSessionActor.activationOptions == [])
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("if the queue player changes current item to nil, calls clear, deactivates session, sets playerState and currentSongIdPublisher")
    func itemChangesToNil() async {
        let subject = Player(
            player: AVQueuePlayer(), // real player!
            commandCenterProvider: { commandCenter },
            trampoline: trampoline,
            audioSessionActor: audioSessionActor
        )
        subject.playerStatePublisher = .playing
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
        let url = #bundle.url(forResource: "4", withExtension: "mp3")! // real song!
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        subject.player.insert(item, after: nil)
        subject.player.play() // play the whole thing so it ends in good order
        await #while(!nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(nowPlayingInfo.methodsCalled.contains("clear()"))
        #expect(await audioSessionActor.methodsCalled.contains("deactivate(options:)"))
        #expect(await audioSessionActor.deactivationOptions == [])
        #expect(subject.currentSongIdPublisher == nil)
        #expect(subject.playerStatePublisher == .empty)
    }

    @Test("if the queue player changes rate to 0, calls now playing info `paused`, sets playerState and currentSongIdPublisher, activates")
    func rateChangesToZero() async throws {
        let subject = Player(
            player: AVQueuePlayer(), // real player!
            commandCenterProvider: { commandCenter },
            trampoline: trampoline,
            audioSessionActor: audioSessionActor
        )
        subject.playerStatePublisher = .playing
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
        let url = #bundle.url(forResource: "4", withExtension: "mp3")! // real song!
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        subject.player.insert(item, after: nil)
        subject.player.play()
        try? await Task.sleep(for: .seconds(0.1)) // give it a chance to start, then test
        subject.player.rate = 0
        await #while(nowPlayingInfo.methodsCalled.last != "paused(song:at:)")
        #expect(nowPlayingInfo.methodsCalled.last == "paused(song:at:)")
        #expect(nowPlayingInfo.song == subject.knownSongs["4"]!)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(await audioSessionActor.methodsCalled.last == "activate(options:)")
        #expect(await audioSessionActor.activationOptions == [])
        guard case .paused(let seconds) = subject.playerStatePublisher else {
            throw NSError(domain: "expected .paused", code: 0)
        }
        #expect(seconds < 0.1)
        #expect(seconds < 0.1)
    }

    @Test("play(url:song:) calls removeAllItems, calls insertAfter nil, sets category active, calls play, sets action to advance, adds to known songs")
    func play() async {
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
        audioPlayer.rate = 0
        subject.play(url: url, song: song)
        await #while(audioPlayer.methodsCalled.count < 4)
        #expect(audioPlayer.methodsCalled == [
            "pause()", "removeAllItems()", "insert(_:after:)", "play()"
        ])
        #expect(audioPlayer.actionAtItemEnd == .advance)
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("play(url:song:) configures now playing info, sets player state and current item publisher")
    func playNowPlayingInfo() async {
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
        audioPlayer.rate = 0
        audioPlayer.time = 10
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        subject.play(url: url, song: song)
        #expect(await audioSessionActor.methodsCalled.contains("activate(options:)"))
        #expect(await audioSessionActor.activationOptions == [])
        #expect(nowPlayingInfo.methodsCalled == ["clear()", "playing(song:at:)"])
        #expect(nowPlayingInfo.song == song)
        #expect(nowPlayingInfo.time == 10)
        #expect(subject.currentSongIdPublisher == "1")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("play(url:song:seconds:) just like play except calls seek before playing")
    func playSeconds() async {
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
        audioPlayer.rate = 0
        subject.play(url: url, song: song, seconds: 1)
        await #while(audioPlayer.methodsCalled.count < 5)
        #expect(audioPlayer.methodsCalled == [
            "pause()", "removeAllItems()", "insert(_:after:)",
            "seek(to:toleranceBefore:toleranceAfter:)", "play()"
        ])
        #expect(audioPlayer.time == 1)
        #expect(audioPlayer.toleranceBefore == .zero)
        #expect(audioPlayer.toleranceAfter == .zero)
        #expect(audioPlayer.actionAtItemEnd == .advance)
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(subject.knownSongs["1"] == song)
    }

    @Test("play(url:song:seconds:) configures now playing info, sets player state and current item publisher")
    func playSecondsNowPlayingInfo() async {
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
        audioPlayer.rate = 0
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/1.what")!))
        subject.play(url: url, song: song, seconds: 1)
        #expect(await audioSessionActor.methodsCalled == ["activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(nowPlayingInfo.methodsCalled == ["clear()", "playing(song:at:)"])
        #expect(nowPlayingInfo.song == song)
        #expect(nowPlayingInfo.time == 1)
        #expect(subject.currentSongIdPublisher == "1")
        #expect(subject.playerStatePublisher == .playing)
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
    func doPlay() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 0
        await subject.doPlay(updateOnly: false)
        #expect(await audioSessionActor.methodsCalled == ["activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("doPlay: if update only true, activates audio session, doesn't call play, tells now playing info playing at current time")
    func doPlayUpdateOnlyTrue() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 1
        await subject.doPlay(updateOnly: true) // *
        #expect(await audioSessionActor.methodsCalled.contains("activate(options:)"))
        #expect(await audioSessionActor.activationOptions == [])
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("doPlay: when paused if update only true, activates audio session, doesn't call play, tells now playing info paused at current time")
    func doPlayUpdateOnlyTruePaused() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 0 // *
        await subject.doPlay(updateOnly: true)
        #expect(await audioSessionActor.methodsCalled.contains("activate(options:)"))
        #expect(await audioSessionActor.activationOptions == [])
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.last == "paused(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .paused(at: 30))
    }

    @Test("skip: false, tells player to seek to 30 seconds back, then same as doPlay update only true")
    func skipBack() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 60
        audioPlayer.rate = 1
        await subject.skip(interval: -30)
        await #while(nowPlayingInfo.time == nil)
        #expect(audioPlayer.methodsCalled == ["currentTime()", "seek(to:toleranceBefore:toleranceAfter:)", "currentTime()"])
        #expect(audioPlayer.time == 30) // 60 - 30
        #expect(audioPlayer.toleranceAfter?.seconds == 0)
        #expect(audioPlayer.toleranceBefore?.seconds == 0)
        #expect(await audioSessionActor.methodsCalled.contains("activate(options:)"))
        #expect(await audioSessionActor.activationOptions == [])
        #expect(!audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("skip: false, when playing tells player to seek to 30 seconds back, if returns false, stops")
    func skipBackReturnFalse() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 60
        audioPlayer.rate = 1
        audioPlayer.boolToReturn = false
        await subject.skip(interval: -30)
        await #while(audioPlayer.time != 30)
        #expect(audioPlayer.methodsCalled == ["currentTime()", "seek(to:toleranceBefore:toleranceAfter:)"]) // *
        #expect(audioPlayer.time == 30) // 60 - 30
        #expect(audioPlayer.toleranceAfter?.seconds == 0)
        #expect(audioPlayer.toleranceBefore?.seconds == 0)
        #expect(await audioSessionActor.methodsCalled.isEmpty)
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
    }

    @Test("skip: true, when playing tells player to seek to 30 seconds forward, then same as doPlay update only true")
    func skipForward() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 60
        audioPlayer.rate = 1
        await subject.skip(interval: 30)
        await #while(nowPlayingInfo.time == nil)
        #expect(audioPlayer.methodsCalled == ["currentTime()", "seek(to:toleranceBefore:toleranceAfter:)", "currentTime()"])
        #expect(audioPlayer.time == 90) // 60 + 30
        #expect(audioPlayer.toleranceAfter?.seconds == 0)
        #expect(audioPlayer.toleranceBefore?.seconds == 0)
        #expect(await audioSessionActor.methodsCalled == ["activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(!audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 90)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("skip: true, when playing tells player to seek to 30 seconds forward, if returns false, stops")
    func skipForwardReturnFalse() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 60
        audioPlayer.rate = 1
        audioPlayer.boolToReturn = false
        await subject.skip(interval: 30)
        await #while(audioPlayer.time != 90)
        #expect(audioPlayer.methodsCalled == ["currentTime()", "seek(to:toleranceBefore:toleranceAfter:)"]) // *
        #expect(audioPlayer.time == 90) // 60 + 30
        #expect(audioPlayer.toleranceAfter?.seconds == 0)
        #expect(audioPlayer.toleranceBefore?.seconds == 0)
        #expect(await audioSessionActor.methodsCalled.isEmpty)
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
    }

    @Test("doPause: calls pause")
    func doPause() async {
        audioPlayer.time = 30
        await subject.doPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
        // and then see `rateChangesToZero` test
    }

    @Test("playPause is like doPlay if rate is 0")
    func playPause() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 0
        await subject.playPause()
        #expect(await audioSessionActor.methodsCalled == ["activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(audioPlayer.methodsCalled.contains("play()"))
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
    }

    @Test("playPause is like doPause if rate is 1")
    func playPauseRate1() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 1
        await subject.playPause()
        #expect(audioPlayer.methodsCalled.contains("pause()"))
    }

    @Test("resumptionRecommendation: if we are playing, nothing happens")
    func resumptionRecommendationRate1() async {
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(await audioSessionActor.methodsCalled.isEmpty)
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
        NotificationCenter.default.post(
            name: AVAudioSession.resumptionRecommendationNotification, object: nil
        )
        try? await Task.sleep(for: .seconds(0.1)) // give something a chance to happen
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(await audioSessionActor.methodsCalled.isEmpty)
        #expect(audioPlayer.methodsCalled.isEmpty)
    }

    @Test("resumptionRecommendation: if we are paused, doPlay followed by doPause")
    func resumptionRecommendation() async {
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(await audioSessionActor.methodsCalled.isEmpty)
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
        NotificationCenter.default.post(
            name: AVAudioSession.resumptionRecommendationNotification, object: nil
        )
        await #while(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(nowPlayingInfo.methodsCalled == ["playing(song:at:)"])
        #expect(nowPlayingInfo.time == 30)
        #expect(await audioSessionActor.methodsCalled == ["activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(audioPlayer.methodsCalled == ["play()", "currentTime()", "pause()"])
        #expect(subject.currentSongIdPublisher == "1")
    }

    @Test("clear: call pause and removeAllItems, empties the known list, nilifies currentSongIdPublisher")
    func clear() async {
        subject.currentSongIdPublisher = "10"
        subject.playerStatePublisher = .playing
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
        await subject.clear()
        #expect(audioPlayer.methodsCalled == ["pause()", "removeAllItems()"])
        #expect(subject.knownSongs.isEmpty)
        #expect(nowPlayingInfo.methodsCalled == ["clear()"])
        #expect(await audioSessionActor.methodsCalled == ["deactivate(options:)"])
        #expect(await audioSessionActor.deactivationOptions == [])
        #expect(subject.currentSongIdPublisher == nil)
        #expect(subject.playerStatePublisher == .empty)
    }

    @Test("backgrounding: if rate is 0, sets audioSession inactive")
    func backgrounding() async {
        audioPlayer.rate = 0
        await subject.backgrounding()
        #expect(await audioSessionActor.methodsCalled == ["deactivate(options:)"])
        #expect(await audioSessionActor.deactivationOptions == [])
    }

    @Test("backgrounding: if rate is 1, does nothing")
    func backgroundingRate1() async {
        audioPlayer.rate = 1
        await subject.backgrounding()
        #expect(await audioSessionActor.methodsCalled.isEmpty)
    }

    @Test("foregrounding: if rate is 1, just like doPlay")
    func foregroundingRate() async {
        audioPlayer.currentItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: "file://1/2/3/4.what")!))
        subject.knownSongs["4"] = SubsonicSong(id: "4", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        audioPlayer.time = 30
        audioPlayer.rate = 1
        await subject.foregrounding()
        await #while(await audioSessionActor.methodsCalled.count < 2)
        #expect(await audioSessionActor.methodsCalled == ["setCategory(_:)", "activate(options:)"])
        #expect(await audioSessionActor.activationOptions == [])
        #expect(!audioPlayer.methodsCalled.contains("play()")) // *
        #expect(nowPlayingInfo.methodsCalled.last == "playing(song:at:)")
        #expect(nowPlayingInfo.time == 30)
        #expect(subject.currentSongIdPublisher == "4")
        #expect(subject.playerStatePublisher == .playing)
    }

    @Test("foregrounding: if rate is 0, does nothing")
    func foregroundingRate0() async {
        audioPlayer.rate = 0
        await subject.foregrounding()
        await #while(await audioSessionActor.methodsCalled.count < 1)
        #expect(nowPlayingInfo.methodsCalled.isEmpty)
        #expect(await audioSessionActor.methodsCalled == ["setCategory(_:)"])
        #expect(audioPlayer.methodsCalled.isEmpty)
        #expect(subject.playerStatePublisher == .empty)
    }
}
