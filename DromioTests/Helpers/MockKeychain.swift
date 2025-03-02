@testable import Dromio
import Foundation

final class MockKeychain: KeychainType {
    var dictionary = [String: String]()

    subscript(key: String) -> String? {
        get {
            dictionary[key]
        }
        set {
            dictionary[key] = newValue
        }
    }
}
