import MediaPlayer

/// Protocol describing an MPRemoteCommand, so we can mock it for testing.
protocol RemoteCommandType: AnyObject {
    func addTarget(_: Any, action: Selector)
    func removeTarget(_: Any?)
    var isEnabled: Bool { get set }
}

/// Extension where MPRemoteCommand adopts our protocol.
extension MPRemoteCommand: RemoteCommandType {}

/// Protocol describing the MPRemoteCommandCenter, so we can mock it for testing.
/// We have to call the commands by different names in order to slot this in with an extension.
protocol RemoteCommandCenterType: AnyObject, Sendable {
    var pause: RemoteCommandType { get }
    var play: RemoteCommandType { get }
    var changePlaybackPosition: RemoteCommandType { get }
}

/// Extension where we make the MPRemoteCommandCenter adopt our protocol.
extension MPRemoteCommandCenter: RemoteCommandCenterType, @retroactive @unchecked Sendable {
    var pause: RemoteCommandType { pauseCommand }
    var play: RemoteCommandType { playCommand }
    var changePlaybackPosition: RemoteCommandType { changePlaybackPositionCommand }
}
