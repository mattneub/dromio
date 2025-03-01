import MediaPlayer
@testable import Dromio

final class MockNowPlayingInfoCenter: NowPlayingInfoCenterType {
    var nowPlayingInfo: [String : Any]?
}
