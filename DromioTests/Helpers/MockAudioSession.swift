@testable import Dromio
import AVFoundation

final class MockAudioSession: AudioSessionType {
    var category: AVAudioSession.Category?
    var methodsCalled = [String]()
    var activationOptions: AVAudioSessionActivationOptions?
    var deactivationOptions: AVAudioSessionDeactivationOptions?

    func setCategory(_ category: AVAudioSession.Category) async throws {
        methodsCalled.append(#function)
        self.category = category
    }

    func activate(options: AVAudioSessionActivationOptions) async throws -> Bool {
        methodsCalled.append(#function)
        self.activationOptions = options
        return true
    }

    func deactivate(options: AVAudioSessionDeactivationOptions) async throws -> Bool {
        methodsCalled.append(#function)
        self.deactivationOptions = options
        return true
    }

}
