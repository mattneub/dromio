@testable import Dromio
import Testing
import Foundation

@MainActor
struct URLMakerTests {
    @Test("urlFor(action:) returns correctly constructed URL for given action")
    func urlfor() throws {
        URLMaker.currentServerInfo = .init(scheme: "scheme", host: "host", port: 1, username: "username", password: "password", version: "version")
        let result = URLMaker.urlFor(action: "action")
        // scheme://host:1/rest/action.view?u=username&s=<salt>&t=<hash>&v=version&c=Dromio&f=json
        let url = try #require(result)
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
}
