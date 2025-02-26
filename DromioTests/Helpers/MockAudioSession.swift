@testable import Dromio
import AVFoundation

@MainActor
final class MockAudioSession: AudioSessionType {

    var methodsCalled = [String]()

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        methodsCalled.append(#function)
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        methodsCalled.append(#function)
    }

}
