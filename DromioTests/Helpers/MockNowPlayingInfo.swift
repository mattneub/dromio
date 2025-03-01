@testable import Dromio
import Testing

final class MockNowPlayingInfo: NowPlayingInfoType {
    var info = [NowPlayingInfoKey: Any]()
    var methodsCalled = [String]()

    func clear() {
        methodsCalled.append(#function)
    }
}
