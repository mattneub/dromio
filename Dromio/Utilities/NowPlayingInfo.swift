import MediaPlayer

protocol NowPlayingInfoType {
    var info: [NowPlayingInfoKey: Any] { get set }
}

final class NowPlayingInfo: NowPlayingInfoType {
    let center = MPNowPlayingInfoCenter.default()

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
