@testable import Dromio
import AVFoundation

final class MockQueuePlayer: QueuePlayerType {
    var rate = Float(0.0)
    var currentItem: AVPlayerItem?
    var actionAtItemEnd: AVPlayer.ActionAtItemEnd = .none

    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var item: AVPlayerItem?
    nonisolated(unsafe) var after: AVPlayerItem?
    nonisolated(unsafe) var time: Double = 100

    func play() {
        methodsCalled.append(#function)
        rate = 1
    }

    func pause() {
        methodsCalled.append(#function)
        rate = 0
    }

    func removeAllItems() {
        methodsCalled.append(#function)
        rate = 0
    }

    func insert(_ item: AVPlayerItem, after: AVPlayerItem?) {
        methodsCalled.append(#function)
        self.item = item
        self.after = after
    }

    func currentTime() -> CMTime {
        methodsCalled.append(#function)
        let time = CMTime(seconds: self.time, preferredTimescale: 1)
        return time
    }

    func addPeriodicTimeObserver(forInterval interval: CMTime, queue: dispatch_queue_t?, using block: @escaping @Sendable (CMTime) -> Void) -> Any {
        methodsCalled.append(#function)
    }

    func removeTimeObserver(_ observer: Any) {
        methodsCalled.append(#function)
    }

}
