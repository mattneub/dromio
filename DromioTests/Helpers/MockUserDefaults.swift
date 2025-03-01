@testable import Dromio
import Foundation

@MainActor
final class MockUserDefaults: UserDefaultsType {
    var methodsCalled = [String]()
    var key: String?
    var value: Any?
    var stringArrayToReturn: [String]?

    func stringArray(forKey key: String) -> [String]? {
        methodsCalled.append(#function)
        self.key = key
        return stringArrayToReturn
    }
    
    func set(_ value: Any?, forKey key: String) {
        methodsCalled.append(#function)
        self.value = value
        self.key = key
    }
}
