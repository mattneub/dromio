@testable import Dromio
import Foundation
import MediaPlayer

final class MockPlayerTrampolineTarget: PlayerTrampolineTargetType {
    var methodsCalled = [String]()
    var updateOnly: Bool?
    var forward: Bool?
    var event: (any RemoteCommandEventType)?
    var status: MPRemoteCommandHandlerStatus = .success

    func doPlay(updateOnly: Bool) {
        methodsCalled.append(#function)
        self.updateOnly = updateOnly
    }

    func doPause() {
        methodsCalled.append(#function)
    }

    func skip(forward: Bool, event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        methodsCalled.append(#function)
        self.forward = forward
        self.event = event
        return status
    }

}
