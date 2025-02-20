import Foundation

/// Error enum that carries a message suitable for display to the user.
enum NetworkerError: Error, Equatable {
    case message(String)
}

/// Protocol defining the public face of our Networker.
@MainActor protocol NetworkerType {
    func performRequest(url: URL) async throws -> Data
}

/// Class embodying all networking activity vis-a-vis the Navidrome server.
@MainActor
final class Networker: NetworkerType {
    let session: URLSession
    
    /// Initializer.
    /// - Parameter session: Optional session, to be used by tests. The app itself should supply nothing
    ///   here, so the Networker instance configures itself.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: config)
            self.session = session
        }
    }

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
