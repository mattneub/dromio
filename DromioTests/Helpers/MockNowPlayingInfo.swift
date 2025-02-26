@testable import Dromio
import Testing

final class MockNowPlayingInfo: NowPlayingInfoType {
    var info = [NowPlayingInfoKey: Any]()
}
