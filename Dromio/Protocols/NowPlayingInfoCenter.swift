import MediaPlayer

/// Protocol that wraps the MPNowPlayingInfoCenter, so we can mock it for testing.
@MainActor
protocol NowPlayingInfoCenterType: AnyObject {
    var nowPlayingInfo: [String : Any]? { get set }
}

extension MPNowPlayingInfoCenter: NowPlayingInfoCenterType {}

