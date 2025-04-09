import AVFoundation

/// Class that provides a reference to the audio session.
@MainActor
final class AudioSessionProvider {
    private let provider: () -> any AudioSessionType
    init(provider: @escaping () -> any AudioSessionType) {
        self.provider = provider
    }
    func provide() -> any AudioSessionType {
        provider()
    }
}
