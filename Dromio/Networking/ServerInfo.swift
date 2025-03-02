import Foundation

/// Struct describing a Navidrome server.
struct ServerInfo: Codable, Equatable {
    let scheme: String
    let host: String
    let port: Int
    let username: String // "u"
    let password: String // used to calculate "t" and "s"
    let version: String // "v"

    func updateWithoutPassword() -> ServerInfo {
        .init(
            scheme: scheme,
            host: host,
            port: port,
            username: username,
            password: "",
            version: version
        )
    }

    func updateWithPassword(_ newPassword: String) -> ServerInfo {
        .init(
            scheme: scheme,
            host: host,
            port: port,
            username: username,
            password: newPassword,
            version: version
        )
    }
}
