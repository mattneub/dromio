import Foundation

@MainActor
protocol URLMakerType {
    var currentServerInfo: ServerInfo? { get set }
    func urlFor(action: String, additional: KeyValuePairs<String, String>?) throws -> URL
}
extension URLMakerType {
    func urlFor(action: String) throws -> URL {
        try urlFor(action: action, additional: nil)
    }
}

/// Struct that embodies the knowledge of how to construct the sort of URL that we request to talk
/// to the Navidrome server.
@MainActor
final class URLMaker: URLMakerType {
    /// Bundle of properties expressing what we need to know about the server to talk to it.
    /// To change what server we talk to, just change this info.
    var currentServerInfo: ServerInfo? = ServerInfo(
        scheme: "http",
        host: "mattneub.ddns.net",
        port: 4533,
        username: "mattneub", // "u"
        password: "bEM§a1oeTh2CEt#",
        version: "1.16.1" // "v"; Navidrome says it is compatible with this
    ) // TODO: Remove those defaults before shipping!

    /// Generate a URL, using the parameters and the information in `currentServerInfo`.
    /// - Parameters:
    ///   - action: String name of the "action", the verb defined by the API.
    ///   - additional: Ordered dictionary of additional key/value pairs specific to this "action".
    /// - Returns: The URL. Throws if the URL cannot be formed.
    ///
    func urlFor(action: String, additional: KeyValuePairs<String, String>? = nil) throws -> URL {
        guard let serverInfo = currentServerInfo else {
            throw NetworkerError.message("There is no current server.")
        }
        let client = "Dromio" // "c"
        let format = "json" // "f"
        let hashAndSalt = PasswordHasher.hash(password: serverInfo.password) // hash is "t", salt is "s"
        var urlComponents = URLComponents()
        urlComponents.scheme = serverInfo.scheme
        urlComponents.host = serverInfo.host
        urlComponents.port = serverInfo.port
        urlComponents.path = "/rest/\(action).view"
        var queries: [URLQueryItem] = [
            .init(name: "u", value: serverInfo.username),
            .init(name: "s", value: hashAndSalt.salt),
            .init(name: "t", value: hashAndSalt.hash),
            .init(name: "v", value: serverInfo.version),
            .init(name: "c", value: client),
            .init(name: "f", value: format)
        ]
        if let additional {
            for (key, value) in additional {
                queries.append(.init(name: key, value: value))
            }
        }
        urlComponents.queryItems = queries
        guard let url = urlComponents.url else {
            throw NetworkerError.message("We created a malformed URL.")
        }
        return url
    }
}
