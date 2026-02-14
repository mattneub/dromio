@testable import Dromio
import Testing
import Foundation

class MockCommand: RemoteCommandType, @unchecked Sendable {
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

class MockSkipCommand: MockCommand, SkipCommandType, @unchecked Sendable {
    var interval: Int?

    func setInterval(_ interval: Int) {
        methodsCalled.append(#function)
        self.interval = interval
    }
}

final class MockRemoteCommandCenter: RemoteCommandCenterType {
    let pause: any RemoteCommandType = MockCommand()
    let play: any RemoteCommandType = MockCommand()
    let changePlaybackPosition: any RemoteCommandType = MockCommand()
    var skipBack: any SkipCommandType = MockSkipCommand()
    var skipForward: any SkipCommandType = MockSkipCommand()
}
