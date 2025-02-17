import Foundation

@MainActor
struct URLMaker {
    static var currentServerInfo: ServerInfo? = ServerInfo(
        scheme: "http",
        host: "mattneub.ddns.net",
        port: 4533,
        username: "mattneub", // "u"
        password: "bEM§a1oeTh2CEt#",
        version: "1.16.1" // "v"; Navidrome says it is compatible with this
    ) // TODO: Remove those defaults before shipping!

    static func urlFor(action: String) -> URL? {
        guard let serverInfo = currentServerInfo else { return nil }
        let client = "Dromio" // "c"
        let format = "json" // "f"
        let hashAndSalt = PasswordHasher.hash(password: serverInfo.password) // hash is "t", salt is "s"
        var urlComponents = URLComponents()
        urlComponents.scheme = serverInfo.scheme
        urlComponents.host = serverInfo.host
        urlComponents.port = serverInfo.port
        urlComponents.path = "/rest/\(action).view"
        let queries: [URLQueryItem] = [
            .init(name: "u", value: serverInfo.username),
            .init(name: "s", value: hashAndSalt.salt),
            .init(name: "t", value: hashAndSalt.hash),
            .init(name: "v", value: serverInfo.version),
            .init(name: "c", value: client),
            .init(name: "f", value: format)
        ]
        urlComponents.queryItems = queries
        return urlComponents.url
    }
}
