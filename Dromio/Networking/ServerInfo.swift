import Foundation

/* Note: the demo server is at (http, not https as stated in the docs) demo.navidrome.org, port 80, demo, demo */

/// Struct describing a Navidrome server.
struct ServerInfo: Codable, Equatable {
    let scheme: String
    let host: String
    let port: Int
    let username: String // "u"
    let password: String // used to calculate "t" and "s"
    let version: String // "v"
    // To specify a server configuration, it is sufficient to combine the username, the host, and the port.
    var id: String { username + "@" + host + ":" + String(port) }

    /// Copy self, replacing the password with an empty string.
    /// - Returns: The copy.
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
    
    /// Copy self, replacing the password with a new password.
    /// - Parameter newPassword: The new password.
    /// - Returns: The copy.
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

    /// Errors that may be thrown by the string-based initializer (see below).
    enum ValidationError: Error {
        case hostEmpty
        case passwordEmpty
        case portEmpty
        case portNotNumber
        case usernameEmpty
        case invalidURL
        case schemeInvalid
        var issue: String {
            switch self {
            case .hostEmpty: "The host cannot be empty."
            case .invalidURL: "A valid URL could not be constructed."
            case .passwordEmpty: "The password cannot be empty."
            case .portEmpty: "The port cannot be empty."
            case .portNotNumber: "The port must be a number (an integer)."
            case .usernameEmpty: "The username cannot be empty."
            case .schemeInvalid: "The scheme must be http or https."
            }
        }
    }
}

extension ServerInfo {
    
    /// String-based initializer. This is useful because what the user enters in the server
    /// interface is mostly strings.
    /// - Parameters:
    ///   - scheme: Scheme, as a string.
    ///   - host: Host, as a string.
    ///   - port: Port, as a string.
    ///   - username: Username, as a string.
    ///   - password: Password, as a string.
    init(
        scheme: String,
        host: String,
        port: String,
        username: String,
        password: String
    ) throws(ValidationError) {
        guard !host.isEmpty else { throw .hostEmpty }
        guard !password.isEmpty else { throw .passwordEmpty }
        guard !username.isEmpty else { throw .usernameEmpty }
        guard !port.isEmpty else { throw .portEmpty }
        guard let port = Int(port) else { throw .portNotNumber }
        guard scheme == "http" || scheme == "https" else { throw .schemeInvalid}
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        guard components.url != nil else { throw .invalidURL }
        self.scheme = scheme
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.version = "1.16.1"
    }
}

