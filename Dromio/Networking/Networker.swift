import Foundation
import UIKit

/// Error enum that carries a message suitable for display to the user.
enum NetworkerError: Error, Equatable {
    case message(String)
}

/// Protocol defining the public face of our Networker.
@MainActor protocol NetworkerType {
    func performRequest(url: URL) async throws -> Data
    func performDownloadRequest(url: URL) async throws -> URL
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

    /// Given a URL, send it as a data request to server and validate the HTTP status code.
    /// - Parameter url: The URL, typically created by URLMaker.
    /// - Returns: The data returned from the server; throws if the status code is not 200.
    func performRequest(url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    /// Given a URL, send it as a download request to server and validate the HTTP status code.
    /// - Parameter url: The URL, typically created by URLMaker.
    /// - Returns: The url returned from the server, containing the downloaded data; throws if the status code is not 200.
    func performDownloadRequest(url: URL) async throws -> URL {
        let request = URLRequest(url: url)
        // Perform the download inside background task boilerplate, in hopes of being allowed to
        // complete it even if the user puts the app into the background as we begin. If the
        // system times us out before the download completes, cancel the download in good order.
        let operation = BackgroundTaskOperation { [weak self] in
            guard let self else { fatalError("oop") }
            logger.log("download started")
            let (url, response) = try await self.session.download(for: request)
            logger.log("download finished")
            return (url, response)
        } cleanup: { [weak self] in
            guard let self else { return }
            for task in await session.allTasks {
                task.cancel()
            }
        }
        let (url, response) = try await operation.start()
        try validate(response: response)
        return url
    }
    
    /// Subroutine that validates the URLResponse returned by server. Throws if not status code 200.
    /// - Parameter response: The URLResponse returned by the server.
    ///
    /// **Note:** Distinguish this use of the word "response" from the _data_ constituting the "response".
    private func validate(response: URLResponse) throws {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw NetworkerError.message("We received a non-HTTPURLResponse.")
        }
        guard statusCode == 200 else {
            throw NetworkerError.message("We got a status code \(statusCode).")
        }
    }
}
