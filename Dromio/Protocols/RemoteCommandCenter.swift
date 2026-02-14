import MediaPlayer

/// Protocol describing an MPRemoteCommand, so we can mock it for testing.
protocol RemoteCommandType: AnyObject, Sendable {
    func addTarget(_: Any, action: Selector)
    func removeTarget(_: Any?)
    var isEnabled: Bool { get set }
}

/// Extension where MPRemoteCommand adopts our protocol.
extension MPRemoteCommand: RemoteCommandType {}

/// Protocol describing an MPSkipIntervalCommand, so we can mock it for testing.
protocol SkipCommandType: RemoteCommandType {
    func setInterval(_: Int)
}

/// Extension where MPSkipIntervalCommand adopts our protocol.
extension MPSkipIntervalCommand: SkipCommandType {
    func setInterval(_ interval: Int) {
        preferredIntervals = [interval as NSNumber]
    }
}

@objc protocol RemoteCommandEventType {}

extension MPRemoteCommandEvent: RemoteCommandEventType {}

protocol SkipIntervalCommandEventType: RemoteCommandEventType {
    var interval: TimeInterval { get }
}

extension MPSkipIntervalCommandEvent: SkipIntervalCommandEventType {}

/// Protocol describing the MPRemoteCommandCenter, so we can mock it for testing.
/// We have to call the commands by different names in order to slot this in with an extension.
protocol RemoteCommandCenterType: AnyObject, Sendable {
    var pause: any RemoteCommandType { get }
    var play: any RemoteCommandType { get }
    var skipBack: any SkipCommandType { get }
    var skipForward: any SkipCommandType { get }
    var changePlaybackPosition: any RemoteCommandType { get }
}

/// Extension where we make the MPRemoteCommandCenter adopt our protocol.
extension MPRemoteCommandCenter: RemoteCommandCenterType, @retroactive @unchecked Sendable {
    var pause: any RemoteCommandType { pauseCommand }
    var play: any RemoteCommandType { playCommand }
    var skipBack: any SkipCommandType { skipBackwardCommand }
    var skipForward: any SkipCommandType { skipForwardCommand }
    var changePlaybackPosition: any RemoteCommandType { changePlaybackPositionCommand }
}
