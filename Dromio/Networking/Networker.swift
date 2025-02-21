import Foundation

/// Error enum that carries a message suitable for display to the user.
enum NetworkerError: Error, Equatable {
    case message(String)
}

/// Protocol defining the public face of our Networker.
@MainActor protocol NetworkerType {
    func performRequest(url: URL) async throws -> Data
}

/// Class embodying all _actual_ networking activity vis-a-vis the Navidrome server. In general,
/// only the RequestMaker should have reason to talk to the Networker; in a sense, the RequestMaker
/// is the public face of the Networker.
@MainActor
final class Networker: NetworkerType {
    /// The URLSession set by `init`.
    let session: URLSession
    
    /// Initializer.
    /// - Parameter session: Optional session, to be used by tests. The app itself should supply nothing
    ///   here, so the Networker instance configures the session itself.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: config)
            self.session = session
        }
    }

    
    /// Given a URL, send it as a request to server and validate the HTTP status code.
    /// - Parameter url: The URL, typically created by URLMaker.
    /// - Returns: The data returned from the server; throws if the status code is not 200.
    func performRequest(url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw NetworkerError.message("We received a non-HTTPURLResponse.")
        }
        guard statusCode == 200 else {
            throw NetworkerError.message("We got a status code \(statusCode).")
        }
        return data
    }
}
