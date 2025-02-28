@testable import Dromio
import AVFoundation

final class MockQueuePlayer: QueuePlayerType {
    var currentItem: AVPlayerItem?

    var actionAtItemEnd: AVPlayer.ActionAtItemEnd = .none

    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var item: AVPlayerItem?
    nonisolated(unsafe) var after: AVPlayerItem?
    nonisolated(unsafe) var time: Double = 100

    func play() {
        methodsCalled.append(#function)
    }

    func pause() {
        methodsCalled.append(#function)
    }

    func removeAllItems() {
        methodsCalled.append(#function)
    }

    func insert(_ item: AVPlayerItem, after: AVPlayerItem?) {
        methodsCalled.append(#function)
        self.item = item
        self.after = after
    }

    func currentTime() -> CMTime {
        methodsCalled.append(#function)
        let time = CMTime(seconds: self.time, preferredTimescale: CMTimeScale(1.0))
        return time
    }
}
