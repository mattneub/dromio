import AVFoundation

/// Class that provides a reference to the audio session.
final class AudioSessionProvider {
    /// Private reference to a function that provides the audio session.
    private let provider: () -> any AudioSessionType

    /// Initializer that takes a provider function.
    /// - Parameter provider: The provider function. The app is not supposed to use this; it is
    ///   for testing. The default is simply to return a reference to the shared audio session instance.
    init(provider: @escaping () -> any AudioSessionType = { AVAudioSession.sharedInstance() }) {
        self.provider = provider
    }

    /// Call the provider function and return the resulting audio session type object.
    func provide() -> any AudioSessionType {
        provider()
    }
}
