import AVFoundation

/// Protocol that wraps AVQueuePlayer, so we can mock it for testing.
protocol QueuePlayerType: AnyObject {
    var currentItem: AVPlayerItem? { get }
    var actionAtItemEnd: AVPlayer.ActionAtItemEnd { get set }
    func removeAllItems()
    func play()
    func pause()
    func insert(_: AVPlayerItem, after: AVPlayerItem?)
    func currentTime() -> CMTime
    var rate: Float { get set }
    func addPeriodicTimeObserver(
        forInterval interval: CMTime,
        queue: dispatch_queue_t?,
        using block: @escaping @Sendable (CMTime) -> Void
    ) -> Any
    func removeTimeObserver(_ observer: Any)
    func seek(
        to: CMTime,
        toleranceBefore: CMTime,
        toleranceAfter: CMTime
    ) async -> Bool
}

extension AVQueuePlayer: QueuePlayerType {}

