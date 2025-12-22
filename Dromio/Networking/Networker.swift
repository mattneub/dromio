import Foundation
import UIKit
import Combine

/// Error enum that carries a message suitable for display to the user.
enum NetworkerError: Error, Equatable {
    case message(String)
}

/// Protocol defining the public face of our Networker.
protocol NetworkerType: Sendable {
    func clear() async
    func performRequest(url: URL) async throws -> Data
    func performDownloadRequest(url: URL) async throws -> URL
    func progress(id: String, fraction: Double?)
    var progress: CurrentValueSubject<(id: String, fraction: Double?), Never> { get }
}

/// Class embodying all _actual_ networking activity vis-a-vis the Navidrome server. In general,
/// only the RequestMaker should have reason to talk to the Networker; in a sense, the RequestMaker
/// is the public face of the Networker. However, the `clear` method is more public than that, because
/// anyone might have reason to tell the Networking to stop whatever it's doing.
final class Networker: NetworkerType {
    /// The URLSession set by `init`.
    let session: any URLSessionType

    /// Publisher of progress in our download task when calling `performDownloadRequest`.
    /// Who has ears to hear, let him hear.
    var progress = CurrentValueSubject<(id: String, fraction: Double?), Never>((id: "-1", fraction: nil))

    /// Initializer.
    /// - Parameter session: Optional session, to be used by tests. The app itself should supply nothing
    ///   here, so the Networker instance configures the session itself.
    init(session: (any URLSessionType)? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 10
            let session = URLSession(configuration: config)
            self.session = session
        }
    }

    /// Stop whatever you're doing and clear the progress subject.
    func clear() async {
        for task in await session.allTasks() {
            task.cancel()
        }
        if let fraction = progress.value.fraction, fraction < 1 {
            progress.send((id: progress.value.id, fraction: 0))
        }
    }

    /// Given a URL, send it as a data request to server and validate the HTTP status code.
    /// - Parameter url: The URL, typically created by URLMaker.
    /// - Returns: The data returned from the server; throws if the status code is not 200.
    func performRequest(url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request, delegate: nil)
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
        let operation = services.backgroundTaskOperationMaker.make { [weak self] in
            guard let self else { fatalError("oop") }
            await logger.debug("download started")
            let (url, response) = try await self.session.download(for: request, delegate: DownloadDelegate())
            await logger.debug("download finished")
            return (url, response)
        } cleanup: { [weak self] in
            guard let self else { return }
            await clear()
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
    
    /// Method called (by DownloadDelegate) to trigger publishing of a download's progress.
    /// - Parameters:
    ///   - id: The `id` of the song we are downloading.
    ///   - fraction: The percentage of progress, as a fraction of 1.
    func progress(id: String, fraction: Double?) {
        let pair = (id: id, fraction: fraction)
        self.progress.send(pair)
    }
}
