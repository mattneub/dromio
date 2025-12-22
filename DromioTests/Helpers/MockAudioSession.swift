@testable import Dromio
import AVFoundation

final class MockAudioSession: AudioSessionType {
    var category: AVAudioSession.Category?
    var active: Bool?
    var methodsCalled = [String]()

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        methodsCalled.append(#function)
        self.category = category
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        methodsCalled.append(#function)
        self.active = active
    }

}
