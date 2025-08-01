import Foundation

/// Protocol that describes the public face of our URLMaker.
@MainActor
protocol URLMakerType {
    var currentServerInfo: ServerInfo? { get set }
    func urlFor(
        action: String,
        additional: [URLQueryItem]?,
        folderRestrictable: Bool
    ) throws -> URL
}
extension URLMakerType {
    func urlFor(action: String) throws -> URL {
        try urlFor(action: action, additional: nil, folderRestrictable: false)
    }
    func urlFor(action: String, additional: [URLQueryItem]) throws -> URL {
        try urlFor(action: action, additional: additional, folderRestrictable: false)
    }
}

/// Struct that embodies the knowledge of how to construct the sort of URL that we request to talk
/// to the Navidrome server. A servant to the RequestMaker.
@MainActor
final class URLMaker: URLMakerType {
    /// Bundle of properties expressing what we need to know about the server to talk to it.
    /// To change what server we talk to, or how we talk to a given server, just change this info.
    var currentServerInfo: ServerInfo?

    /// Generate a URL, using the parameters and the information in `currentServerInfo`.
    /// - Parameters:
    ///   - action: String name of the "action", the verb defined by the API.
    ///   - additional: Array of additional query items specific to this "action".
    ///   - folderRestrictable: Whether to limit to the current music folder if there is one; this
    ///       is equivalent to stating whether this action takes an optional music folder id. Default false.
    /// - Returns: The URL. Throws if the URL cannot be formed.
    ///
    func urlFor(action: String, additional: [URLQueryItem]? = nil, folderRestrictable: Bool = false) throws -> URL {
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
        urlComponents.queryItems = [
            .init(name: "u", value: serverInfo.username),
            .init(name: "s", value: hashAndSalt.salt),
            .init(name: "t", value: hashAndSalt.hash),
            .init(name: "v", value: serverInfo.version),
            .init(name: "c", value: client),
            .init(name: "f", value: format)
        ] + (additional ?? [])
        if folderRestrictable, let folderId = currentFolder {
            urlComponents.queryItems?.append(.init(name: "musicFolderId", value: String(folderId)))
        }
        guard let url = urlComponents.url else {
            throw NetworkerError.message("We created a malformed URL.")
        }
        return url
    }
}
