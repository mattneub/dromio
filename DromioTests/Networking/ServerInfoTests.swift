@testable import Dromio
import Testing

@MainActor
struct ServerInfoTests {
    let subject = ServerInfo.init(
        scheme: "s",
        host: "h",
        port: 1,
        username: "u",
        password: "p",
        version: "v"
    )

    @Test("update without password strips password")
    func updateWithout() {
        let result = subject.updateWithoutPassword()
        #expect(result.scheme == "s")
        #expect(result.host == "h")
        #expect(result.port == 1)
        #expect(result.username == "u")
        #expect(result.password == "")
        #expect(result.version == "v")
        #expect(result.id == "u@h:1")
    }

    @Test("update with password replaces password")
    func updateWith() {
        let result = subject.updateWithPassword("1234")
        #expect(result.scheme == "s")
        #expect(result.host == "h")
        #expect(result.port == 1)
        #expect(result.username == "u")
        #expect(result.password == "1234")
        #expect(result.version == "v")
        #expect(result.id == "u@h:1")
    }

    @Test("initializer from strings throws if scheme is not http/s")
    func initScheme() {
        #expect {
            let _ = try ServerInfo(
                scheme: "s",
                host: "h",
                port: "1",
                username: "u",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .schemeInvalid
        }
    }

    @Test("initializer from strings throws if host is empty")
    func initHost() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "",
                port: "1",
                username: "u",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .hostEmpty
        }
    }

    @Test("initializer from strings throws if port is empty")
    func initPort() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "h",
                port: "",
                username: "u",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .portEmpty
        }
    }

    @Test("initializer from strings throws if port is not numeric")
    func initPortNumber() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "h",
                port: "p",
                username: "u",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .portNotNumber
        }
    }

    @Test("initializer from strings throws if username is empty")
    func initUsername() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "h",
                port: "1",
                username: "",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .usernameEmpty
        }
    }

    @Test("initializer from strings throws if password is empty")
    func initPassword() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "h",
                port: "1",
                username: "u",
                password: ""
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .passwordEmpty
        }
    }

    @Test("initializer from string throws if URL cannot be assembled")
    func initBadURL() {
        #expect {
            let _ = try ServerInfo(
                scheme: "http",
                host: "1./?",
                port: "1",
                username: "u",
                password: "p"
            )
        } throws: { error in
            let error = try #require(error as? ServerInfo.ValidationError)
            return error == .invalidURL
        }
    }

    @Test("initializer from string gives expected result if all is well, http")
    func initGoodHttp() throws {
        let result = try ServerInfo(
            scheme: "http",
            host: "h",
            port: "1",
            username: "u",
            password: "p"
        )
        #expect(
            result == .init(
                scheme: "http",
                host: "h",
                port: 1,
                username: "u",
                password: "p",
                version: "1.16.1"
            )
        )
        #expect(result.id == "u@h:1")
    }

    @Test("initializer from string gives expected result if all is well, https")
    func initGoodHttps() throws {
        let result = try ServerInfo(
            scheme: "https",
            host: "h",
            port: "1",
            username: "u",
            password: "p"
        )
        #expect(
            result == .init(
                scheme: "https",
                host: "h",
                port: 1,
                username: "u",
                password: "p",
                version: "1.16.1"
            )
        )
        #expect(result.id == "u@h:1")
    }
}
