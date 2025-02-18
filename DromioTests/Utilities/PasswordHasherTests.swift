@testable import Dromio
import Testing

@MainActor
struct PasswordHasherTests {
    @Test("md5: generates correct md5 hash of given string")
    func md5() {
        let subject = "howdy"
        let hash = subject.md5
        #expect(hash == "0782efd61b7a6b02e602cc6a11673ec9")
    }

    @Test("hash: removes hyphens from salt, appends salt to pwd, gets hash, returns result")
    func hash() {
        let password = "how"
        let salt = "-dy-"
        let result = PasswordHasher.hash(password: password, salt: salt)
        #expect(result.hash == "0782efd61b7a6b02e602cc6a11673ec9")
        #expect(result.salt == "dy")
    }

    @Test("hash: call with no salt returns salt that can be used to confirm hash")
    func hashMultiple() {
        let result = PasswordHasher.hash(password: "howdy")
        let base = "howdy" + result.salt
        let hash = base.md5
        #expect(hash == result.hash)
        #expect(result.salt.count == 32) // UUID string with no hyphens
    }
}
