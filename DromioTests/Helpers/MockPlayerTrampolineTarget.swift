@testable import Dromio
import Foundation
import MediaPlayer

final class MockPlayerTrampolineTarget: PlayerTrampolineTargetType {
    var methodsCalled = [String]()
    var updateOnly: Bool?
    var interval: TimeInterval?

    func doPlay(updateOnly: Bool) async {
        methodsCalled.append(#function)
        self.updateOnly = updateOnly
    }

    func doPause() async {
        methodsCalled.append(#function)
    }

    func skip(interval: TimeInterval) async {
        methodsCalled.append(#function)
        self.interval = interval
    }

}
