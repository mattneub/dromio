@testable import Dromio
import Testing
import Foundation

class MockCommand: RemoteCommandType {
    var methodsCalled = [String]()
    var enabled: Bool = true
    weak var target: AnyObject? // must be weak or we will leak Players during testing, which is disastrous
    var action: Selector?

    func addTarget(_ target: Any, action: Selector) {
        methodsCalled.append(#function)
        self.target = target as AnyObject
        self.action = action
    }
    
    func removeTarget(_ target: Any?) {
        methodsCalled.append(#function)
    }
    
    var isEnabled: Bool = true {
        didSet {
            self.enabled = isEnabled
        }
    }

}

final class MockRemoteCommandCenter: RemoteCommandCenterType {
    nonisolated(unsafe) let pause: any RemoteCommandType = MockCommand()
    nonisolated(unsafe) let play: any RemoteCommandType = MockCommand()
    nonisolated(unsafe) let changePlaybackPosition: any RemoteCommandType = MockCommand()
}
