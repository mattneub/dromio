@testable import Dromio
import Testing
import Foundation
import MediaPlayer

nonisolated
final class MockSkipIntervalCommandEvent: SkipIntervalCommandEventType {
    var _interval: TimeInterval = 30
    var interval: TimeInterval { _interval }
}
