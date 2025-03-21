@testable import Dromio
import Testing
import UIKit

@MainActor struct SceneDelegateTests {
    @Test("bootstrap: tells the root coordinator to create the interface")
    func testBootstrap() async throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        let mockRootCoordinator = MockRootCoordinator()
        subject.rootCoordinator = mockRootCoordinator
        subject.bootstrap(scene: scene)
        let window = try #require(subject.window)
        #expect(window.isKeyWindow)
        #expect(mockRootCoordinator.methodsCalled == ["createInitialInterface(window:)"])
    }

    @Test("sceneWillEnterForeground: sets the audio session category, calls player foregrounding")
    func testForeground() throws {
        let mockAudioSession = MockAudioSession()
        services.audioSession = mockAudioSession
        let player = MockPlayer()
        services.player = player
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        subject.sceneWillEnterForeground(scene)
        #expect(mockAudioSession.methodsCalled == ["setCategory(_:mode:options:)"])
        #expect(mockAudioSession.category == .playback)
        #expect(player.methodsCalled == ["foregrounding()"])
    }

    @Test("sceneDidEnterBackground: calls player backgrounding")
    func testBackground() throws {
        let player = MockPlayer()
        services.player = player
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        subject.sceneDidEnterBackground(scene)
        #expect(player.methodsCalled == ["backgrounding()"])
    }
}
