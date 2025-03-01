import MediaPlayer

protocol NowPlayingInfoCenterType {
    var nowPlayingInfo: [String : Any]? { get set }
}

extension MPNowPlayingInfoCenter: NowPlayingInfoCenterType {}

protocol NowPlayingInfoType {
    var info: [NowPlayingInfoKey: Any] { get set }
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
