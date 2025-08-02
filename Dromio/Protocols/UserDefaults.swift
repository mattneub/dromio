import Foundation

/// Protocol wrapping UserDefaults, so we can mock it for testing.
@MainActor
protocol UserDefaultsType {
    func object(forKey: String) -> Any?
    func stringArray(forKey: String) -> [String]?
    func set(_ value: Any?, forKey: String )
}

extension UserDefaults: UserDefaultsType {}

