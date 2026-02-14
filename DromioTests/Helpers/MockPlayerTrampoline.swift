@testable import Dromio
import Foundation
import MediaPlayer

final class MockPlayerTrampoline: PlayerTrampolineType {
    /// Dummy reference to the player — dummy so that we never retain one by mistake,
    /// which would be disastrous during testing.
    var player: (any PlayerTrampolineTargetType)? {
        get { nil }
        set {}
    }

    var status: MPRemoteCommandHandlerStatus = .success

    @objc func doPlay(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return status
    }

    @objc func doPause(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return status
    }

    @objc func doSkipBack(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return status
    }

    @objc func doSkipForward(_ event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        return status
    }
}
