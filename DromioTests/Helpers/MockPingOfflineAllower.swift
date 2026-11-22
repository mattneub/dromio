@testable import Dromio
import Foundation

final class MockPingOfflineAllower: PingOfflineAllowerType {
    var boolToReturn = false
    func canShowOfflineModeButton() async -> Bool {
        return boolToReturn
    }
}
