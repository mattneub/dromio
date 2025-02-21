import Foundation
import CryptoKit

/// Struct embodying the knowledge of how to assemble the password hash to be sent to the server
/// as part of every request.
struct PasswordHasher {
    
    /// Given an actual password, generate a salt and return both the salt and the combinatory hash
    /// of the password and salt.
    /// - Parameters:
    ///   - password: The actual password.
    ///   - salt: Salt to use. Optional; should be used only for testing, because in real life the
    ///       salt is random and different on every call.
    /// - Returns: The hash to send to the server, along with the salt that was used, also to be
    ///       used by the server.
    static func hash(password: String, salt: String = UUID().uuidString) -> (hash: String, salt: String) {
        let salt = salt.replacingOccurrences(of: "-", with: "") // s
        let passwordPlusSalt = password + salt
        let hash = passwordPlusSalt.md5 // t
        return (hash: hash, salt: salt)
    }
}

extension String {
    /// Turn the target string into an md5 hash string, and return it.
    var md5: String {
        Insecure.MD5.hash(data: Data(self.utf8))
            .map { String(format: "%02hhx", $0) }
            .joined()
    }
}
