@testable import Dromio
import Testing
import UIKit

struct SceneDelegateTests {
    @Test("bootstrap: tells the root coordinator to create the interface")
    func testBootstrap() async throws {
        let restrictor = MockSceneSizeRestrictor()
        services.sceneSizeRestrictor = restrictor
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        let mockRootCoordinator = MockRootCoordinator()
        subject.rootCoordinator = mockRootCoordinator
        subject.bootstrap(scene: scene)
        let window = try #require(subject.window)
        #expect(window.isKeyWindow)
        #expect(mockRootCoordinator.methodsCalled == ["createInitialInterface(window:)"])
        #expect(restrictor.scene === scene)
        #expect(restrictor.minimumSize == .init(width: 500, height: 800))
        #expect(restrictor.maximumSize == .init(width: 600, height: 1000))
    }

    @Test("sceneWillEnterForeground: calls player foregrounding")
    func testForeground() throws {
        let mockAudioSession = MockAudioSession()
        services.audioSessionProvider = AudioSessionProvider { mockAudioSession }
        let player = MockPlayer()
        services.player = player
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        subject.sceneWillEnterForeground(scene)
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

    @Test("preferred windowing control style is correct")
    func controlStyle() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        let result = subject.preferredWindowingControlStyle(for: scene)
        // for some reason, this value is not equatable in the way you'd expect
        // so we take advantage of the way it prints itself
        // (perhaps could have jumped into Objective-C, but not worth finding out_
        let description = String(describing: result)
        #expect(description.contains("type: minimal"))
    }
}
