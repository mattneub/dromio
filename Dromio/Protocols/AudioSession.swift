import AVFoundation

/// Protocol describing AVAudioSession, so we can mock it for testing.
protocol AudioSessionType: AnyObject {
    func setCategory(_: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AudioSessionType {}
