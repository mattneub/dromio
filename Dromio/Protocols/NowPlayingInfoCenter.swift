import MediaPlayer

/// Protocol that wraps the MPNowPlayingInfoCenter, so we can mock it for testing.
protocol NowPlayingInfoCenterType {
    var nowPlayingInfo: [String : Any]? { get set }
}

extension MPNowPlayingInfoCenter: NowPlayingInfoCenterType {}

