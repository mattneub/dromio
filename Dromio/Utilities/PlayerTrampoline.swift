import MediaPlayer

/// Protocol describing the Player, as seen by the PlayerTrampoline.
@objc protocol PlayerTrampolineTargetType: AnyObject {
    func doPlay(updateOnly: Bool)
    func doPause()
    func skip(forward: Bool, event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
}

/// Public face of the PlayerTrampoline type, so we can mock it for testing.
@objc protocol PlayerTrampolineType: AnyObject {
    var player: (any PlayerTrampolineTargetType)? { get set }
    @objc func doPlay(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doPause(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doSkipBack(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
    @objc func doSkipForward(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus
}

/// Class whose instance acts as the recipient of remote command events. This greatly
/// simplifies testing to prove that the methods here behave as expected.
final class PlayerTrampoline: NSObject, PlayerTrampolineType {
    weak var player: (any PlayerTrampolineTargetType)?

    /// Response to the remote command center saying "play".
    @objc func doPlay(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.debug("doPlay")
        player?.doPlay(updateOnly: false)
        return .success
    }

    /// Response to the remote command center saying "pause".
    @objc func doPause(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        logger.debug("doPause")
        player?.doPause()
        return .success
    }

    /// Response to the remote command center saying "skipBack".
    @objc func doSkipBack(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return player?.skip(forward: false, event: event) ?? .commandFailed
    }

    /// Response to the remote command center saying "skipForward".
    @objc func doSkipForward(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return player?.skip(forward: true, event: event) ?? .commandFailed
    }

}
