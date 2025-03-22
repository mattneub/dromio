@testable import Dromio
import Foundation

@MainActor
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
