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

    @Test("play(url:song:) replaces player item, activates audio session, calls play")
    func play() {
        let song = SubsonicSong(id: "1", title: "title", artist: "artist", track: 1, albumId: nil, suffix: nil, duration: nil)
        let url = URL(string: "http://example.com")!
        subject.play(url: url, song: song)
        #expect(audioPlayer.methodsCalled.contains("replaceCurrentItem(with:)"))
        #expect((audioPlayer.item?.asset as? AVURLAsset)?.url == url)
        #expect(audioSession.methodsCalled == ["setActive(_:options:)"])
        #expect(audioPlayer.methodsCalled.contains("play()"))
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

}

final class MockQueuePlayer: AVQueuePlayer {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var item: AVPlayerItem?
    nonisolated(unsafe) var time: Double = 100

    override func play() {
        methodsCalled.append(#function)
    }

    override func pause() {
        methodsCalled.append(#function)
    }

    override func replaceCurrentItem(with item: AVPlayerItem?) {
        methodsCalled.append(#function)
        self.item = item
    }

    override func currentTime() -> CMTime {
        methodsCalled.append(#function)
        let time = CMTime(seconds: self.time, preferredTimescale: CMTimeScale(1.0))
        return time
    }
}
