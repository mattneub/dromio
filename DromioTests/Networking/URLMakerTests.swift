@testable import Dromio
import Testing
import Foundation

struct URLMakerTests {
    let subject = URLMaker()
    let persistence = MockPersistence()

    init() {
        services.persistence = persistence
        persistence.currentFolder = nil
    }

    @Test("subject is born with a nil current server")
    func nilCurrentServer() {
        #expect(subject.currentServerInfo == nil)
    }

    @Test("urlFor(action:) returns correctly constructed URL for given action")
    func urlfor() throws {
        subject.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let url = try subject.urlFor(action: "action")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        #expect(components.scheme == "scheme")
        #expect(components.host == "host")
        #expect(components.port == 1)
        #expect(components.path == "/rest/action.view")
        var query = try #require(components.queryItems)
        var item = query.popLast()
        #expect(item?.name == "f")
        #expect(item?.value == "json")
        item = query.popLast()
        #expect(item?.name == "c")
        #expect(item?.value == "Dromio")
        item = query.popLast()
        #expect(item?.name == "v")
        #expect(item?.value == "version")
        let hashItem = query.popLast()
        let saltItem = query.popLast()
        #expect(hashItem?.name == "t")
        #expect(saltItem?.name == "s")
        let hash = ("password" + (saltItem?.value ?? "")).md5
        #expect(hashItem?.value == hash)
        item = query.popLast()
        #expect(item?.name == "u")
        #expect(item?.value == "username")
        #expect(query.isEmpty)
    }

    @Test("urlFor(action:) returns correctly constructed URL for given action and extra query pairs")
    func urlforWithAdditional() throws {
        subject.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let url = try subject.urlFor(action: "action", additional: [
            .init(name: "nickname", value: "mattski"),
            .init(name: "age", value: "70")
        ])
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        #expect(components.scheme == "scheme")
        #expect(components.host == "host")
        #expect(components.port == 1)
        #expect(components.path == "/rest/action.view")
        var query = try #require(components.queryItems)
        var item = query.popLast()
        #expect(item?.name == "age")
        #expect(item?.value == "70")
        item = query.popLast()
        #expect(item?.name == "nickname")
        #expect(item?.value == "mattski")
        item = query.popLast()
        #expect(item?.name == "f")
        #expect(item?.value == "json")
        item = query.popLast()
        #expect(item?.name == "c")
        #expect(item?.value == "Dromio")
        item = query.popLast()
        #expect(item?.name == "v")
        #expect(item?.value == "version")
        let hashItem = query.popLast()
        let saltItem = query.popLast()
        #expect(hashItem?.name == "t")
        #expect(saltItem?.name == "s")
        let hash = ("password" + (saltItem?.value ?? "")).md5
        #expect(hashItem?.value == hash)
        item = query.popLast()
        #expect(item?.name == "u")
        #expect(item?.value == "username")
        #expect(query.isEmpty)
    }

    @Test("urlFor(action:) adds musicFolderId query item if folder restrictable and current folder is non-nil")
    func folderRestrictable() throws {
        persistence.currentFolderId = 2
        subject.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let url = try subject.urlFor(action: "action", additional: [
            .init(name: "nickname", value: "mattski"),
            .init(name: "age", value: "70")
        ], folderRestrictable: true) // *
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        #expect(components.scheme == "scheme")
        #expect(components.host == "host")
        #expect(components.port == 1)
        #expect(components.path == "/rest/action.view")
        var query = try #require(components.queryItems)
        var item = query.popLast()
        #expect(item?.name == "musicFolderId") // **
        #expect(item?.value == "2") // **
        item = query.popLast()
        #expect(item?.name == "age")
        #expect(item?.value == "70")
        item = query.popLast()
        #expect(item?.name == "nickname")
        #expect(item?.value == "mattski")
        item = query.popLast()
        #expect(item?.name == "f")
        #expect(item?.value == "json")
        item = query.popLast()
        #expect(item?.name == "c")
        #expect(item?.value == "Dromio")
        item = query.popLast()
        #expect(item?.name == "v")
        #expect(item?.value == "version")
        let hashItem = query.popLast()
        let saltItem = query.popLast()
        #expect(hashItem?.name == "t")
        #expect(saltItem?.name == "s")
        let hash = ("password" + (saltItem?.value ?? "")).md5
        #expect(hashItem?.value == hash)
        item = query.popLast()
        #expect(item?.name == "u")
        #expect(item?.value == "username")
        #expect(query.isEmpty)
    }

    @Test("urlFor(action:) doesn't add musicFolderId query item if not folder restrictable and current folder is non-nil")
    func folderRestrictableNot() throws {
        persistence.currentFolderId = 2
        subject.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let url = try subject.urlFor(action: "action", additional: [
            .init(name: "nickname", value: "mattski"),
            .init(name: "age", value: "70")
        ], folderRestrictable: false) // *
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        #expect(components.scheme == "scheme")
        #expect(components.host == "host")
        #expect(components.port == 1)
        #expect(components.path == "/rest/action.view")
        var query = try #require(components.queryItems)
        var item = query.popLast()
        #expect(item?.name == "age")
        #expect(item?.value == "70")
        item = query.popLast()
        #expect(item?.name == "nickname")
        #expect(item?.value == "mattski")
        item = query.popLast()
        #expect(item?.name == "f")
        #expect(item?.value == "json")
        item = query.popLast()
        #expect(item?.name == "c")
        #expect(item?.value == "Dromio")
        item = query.popLast()
        #expect(item?.name == "v")
        #expect(item?.value == "version")
        let hashItem = query.popLast()
        let saltItem = query.popLast()
        #expect(hashItem?.name == "t")
        #expect(saltItem?.name == "s")
        let hash = ("password" + (saltItem?.value ?? "")).md5
        #expect(hashItem?.value == hash)
        item = query.popLast()
        #expect(item?.name == "u")
        #expect(item?.value == "username")
        #expect(query.isEmpty)
    }

    @Test("urlFor(action:) doesn't add musicFolderId query item if folder restrictable but current folder is nil")
    func folderRestrictableButCurrentFolderNil() throws {
        subject.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let url = try subject.urlFor(action: "action", additional: [
            .init(name: "nickname", value: "mattski"),
            .init(name: "age", value: "70")
        ], folderRestrictable: true) // *
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        #expect(components.scheme == "scheme")
        #expect(components.host == "host")
        #expect(components.port == 1)
        #expect(components.path == "/rest/action.view")
        var query = try #require(components.queryItems)
        var item = query.popLast()
        #expect(item?.name == "age")
        #expect(item?.value == "70")
        item = query.popLast()
        #expect(item?.name == "nickname")
        #expect(item?.value == "mattski")
        item = query.popLast()
        #expect(item?.name == "f")
        #expect(item?.value == "json")
        item = query.popLast()
        #expect(item?.name == "c")
        #expect(item?.value == "Dromio")
        item = query.popLast()
        #expect(item?.name == "v")
        #expect(item?.value == "version")
        let hashItem = query.popLast()
        let saltItem = query.popLast()
        #expect(hashItem?.name == "t")
        #expect(saltItem?.name == "s")
        let hash = ("password" + (saltItem?.value ?? "")).md5
        #expect(hashItem?.value == hash)
        item = query.popLast()
        #expect(item?.name == "u")
        #expect(item?.value == "username")
        #expect(query.isEmpty)
    }

}
