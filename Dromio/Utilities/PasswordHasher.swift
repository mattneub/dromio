import Foundation
import CryptoKit

struct PasswordHasher {
    static func hash(password: String) -> (hash: String, salt: String) {
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "") // s
        let passwordPlusSalt = password + salt
        let hash = passwordPlusSalt.md5 // t
        return (hash: hash, salt: salt)
    }
}

extension String {
    var md5: String {
        Insecure.MD5.hash(data: Data(self.utf8))
            .map { String(format: "%02hhx", $0) }
            .joined()
    }
}
