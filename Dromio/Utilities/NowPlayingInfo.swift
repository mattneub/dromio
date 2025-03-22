import MediaPlayer

protocol NowPlayingInfoCenterType {
    var nowPlayingInfo: [String : Any]? { get set }
}

extension MPNowPlayingInfoCenter: NowPlayingInfoCenterType {}

protocol NowPlayingInfoType {
    var info: [NowPlayingInfoKey: Any] { get set }
    func display(song: SubsonicSong)
    func playingAt(_: TimeInterval)
    func pausedAt(_: TimeInterval)
    func clear()
}

final class NowPlayingInfo: NowPlayingInfoType {
    var center: NowPlayingInfoCenterType = MPNowPlayingInfoCenter.default()

    var info: [NowPlayingInfoKey: Any] = [:] {
        didSet {
            if center.nowPlayingInfo == nil {
                center.nowPlayingInfo = [:]
            }
            if var centerInfo = center.nowPlayingInfo {
                for (key, value) in info {
                    centerInfo[key.value] = value
                }
                center.nowPlayingInfo = centerInfo
            }
        }
    }

    func display(song: SubsonicSong) {
        info[.artist] = song.artist
        info[.title] = song.title
        info[.duration] = song.duration ?? 60
    }

    func playingAt(_ time: TimeInterval) {
        info[.time] = time
        info[.rate] = 1.0
    }

    func pausedAt(_ time: TimeInterval) {
        // order matters!
        info[.time] = time
        info[.rate] = 0.0
    }

    func clear() {
        center.nowPlayingInfo = nil
    }
}

struct NowPlayingInfoKey: Hashable {
    let value: String

    init(value: String) {
        self.value = value
    }

    static let artist = NowPlayingInfoKey(value: MPMediaItemPropertyArtist)
    static let title = NowPlayingInfoKey(value: MPMediaItemPropertyTitle)
    static let duration = NowPlayingInfoKey(value: MPMediaItemPropertyPlaybackDuration)
    static let time = NowPlayingInfoKey(value: MPNowPlayingInfoPropertyElapsedPlaybackTime)
    static let rate = NowPlayingInfoKey(value: MPNowPlayingInfoPropertyPlaybackRate)
}
