@testable import Dromio
import Testing
import Foundation
import MediaPlayer

nonisolated
final class MockSkipIntervalCommandEvent: SkipIntervalCommandEventType {
    var _interval: TimeInterval = 0
    var interval: TimeInterval { _interval }
}
