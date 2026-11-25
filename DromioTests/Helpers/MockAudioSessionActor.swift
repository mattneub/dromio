@testable import Dromio
import AVFoundation

actor MockAudioSessionActor: AudioSessionActorType {
    var category: AVAudioSession.Category?
    var activationOptions: AVAudioSessionActivationOptions?
    var deactivationOptions: AVAudioSessionDeactivationOptions?
    var methodsCalled = [String]()

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
