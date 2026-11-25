@testable import Dromio
import Testing
import AVFoundation

struct AudioSessionActorTests {
    let subject = AudioSessionActor()
    let session: MockAudioSession!

    init() {
        let session = MockAudioSession()
        services.audioSessionProvider = AudioSessionProvider { session }
        self.session = session
    }

    @Test("setCategory: sets category on session")
    func setCategory() async {
        try? await subject.setCategory(.playback)
        #expect(session.methodsCalled == ["setCategory(_:)"])
        #expect(session.category == .playback)
    }

    @Test("activate: calls activate on session")
    func activate() async {
        _ = try? await subject.activate(options: [])
        #expect(session.methodsCalled == ["activate(options:)"])
        #expect(session.activationOptions == [])
    }

    @Test("deactivate: calls deactivate on session")
    func deactivate() async {
        _ = try? await subject.deactivate(options: [])
        #expect(session.methodsCalled == ["deactivate(options:)"])
        #expect(session.deactivationOptions == [])
    }

}
