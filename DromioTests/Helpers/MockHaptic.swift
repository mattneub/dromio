@testable import Dromio
import Foundation

final class MockHaptic: HapticType {
    var methodsCalled = [String]()

    func success() {
        methodsCalled.append(#function)
    }

    func failure() {
        methodsCalled.append(#function)
    }

    func impact() {
        methodsCalled.append(#function)
    }

}
