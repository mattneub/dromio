import MediaPlayer
import os.log

/// Protocol describing the Player, as seen by the PlayerTrampoline.
@objc protocol PlayerTrampolineTargetType: AnyObject {
    func doPlay(updateOnly: Bool) async
    func doPause() async
    func skip(interval: TimeInterval) async
}

/// Public face of the PlayerTrampoline type, so we can mock it for testing.
@objc protocol PlayerTrampolineType: AnyObject {
    var player: any PlayerTrampolineTargetType? { get set }
    @objc func doPlay(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doPause(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doSkipBack(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doSkipForward(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
}

/// Class whose instance acts as the recipient of remote command events. This greatly
/// simplifies testing to prove that the methods here behave as expected.
final class PlayerTrampoline: NSObject, PlayerTrampolineType {
    weak var player: any PlayerTrampolineTargetType?

    /// Response to the remote command center saying "play".
    @objc func doPlay(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.info("doPlay")
        Task.immediate {
            await player?.doPlay(updateOnly: false)
        }
        return .success
    }

    /// Response to the remote command center saying "pause".
    @objc func doPause(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.info("doPause")
        Task.immediate {
            await player?.doPause()
        }
        return .success
    }

    /// Response to the remote command center saying "skipBack".
    @objc func doSkipBack(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.info("doSkipBack")
        guard let event = event as? any SkipIntervalCommandEventType else {
            return .commandFailed
        }
        let interval = -event.interval // always 30 in fact
        Task.immediate {
            await player?.skip(interval: interval)
        }
        return .success
    }

    /// Response to the remote command center saying "skipForward".
    @objc func doSkipForward(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.info("doSkipForward")
        guard let event = event as? any SkipIntervalCommandEventType else {
            return .commandFailed
        }
        let interval = event.interval // always 30 in fact
        Task.immediate {
            await player?.skip(interval: interval)
        }
        return .success
    }

}
