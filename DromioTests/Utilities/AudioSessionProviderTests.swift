@testable import Dromio
import Testing
import UIKit
import AVFoundation

struct AudioSessionProviderTests {
    @Test("audio session provider by default provides the shared audio session")
    func provide() {
        let subject = AudioSessionProvider()
        let product = subject.provide()
        #expect(product === AVAudioSession.sharedInstance())
    }
}
