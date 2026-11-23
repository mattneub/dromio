@testable import Dromio
import UIKit

final class MockSceneSizeRestrictor: SceneSizeRestrictorType {
    var scene: UIWindowScene?
    var minimumSize: CGSize?
    var maximumSize: CGSize?
    func restrict(scene: UIWindowScene, minimumSize: CGSize?, maximumSize: CGSize?) {
        self.scene = scene
        self.minimumSize = minimumSize
        self.maximumSize = maximumSize
    }
}
