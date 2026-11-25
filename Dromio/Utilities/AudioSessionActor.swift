import AVFoundation

/// Public face of our audio session actor, so we can mock it for testing.
protocol AudioSessionActorType: Actor {
    func setCategory(_ category: AVAudioSession.Category) async throws
    func activate(options: AVAudioSessionActivationOptions) async throws -> Bool
    func deactivate(options: AVAudioSessionDeactivationOptions) async throws -> Bool
}

/// Actor that moves our communication with the audio session off the main thread.
actor AudioSessionActor: AudioSessionActorType {
    func setCategory(_ category: AVAudioSession.Category) async throws {
        try await services.audioSessionProvider.provide().setCategory(category)
    }
    func activate(options: AVAudioSessionActivationOptions) async throws -> Bool {
        return try await services.audioSessionProvider.provide().activate(options: options)
    }
    func deactivate(options: AVAudioSessionDeactivationOptions) async throws -> Bool {
        return try await services.audioSessionProvider.provide().deactivate(options: options)
    }

}
