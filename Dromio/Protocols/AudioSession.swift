import AVFoundation

/// Protocol describing AVAudioSession, so we can mock it for testing.
protocol AudioSessionType: AnyObject, Sendable {
    func setCategory(_: AVAudioSession.Category) async throws
    func activate(options: AVAudioSessionActivationOptions) async throws -> Bool
    func deactivate(options: AVAudioSessionDeactivationOptions) async throws -> Bool
}

extension AVAudioSession: AudioSessionType {}
