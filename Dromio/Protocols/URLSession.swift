import Foundation

/// Protocol wrapping URLSession so we can mock it for testing.
protocol URLSessionType: Sendable {
    /// In this way, we make `allTasks` return a protocol-typed instance so we can mock that too.
    func allTasks() async -> [any URLSessionTaskType]

    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)

    func download(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (URL, URLResponse)
}

/// Extension where we make URLSession adopt our protocol.
extension URLSession: URLSessionType {
    func allTasks() async -> [any URLSessionTaskType] { await allTasks }
}

/// Protocol wrapping URLSessionTask so we can mock it for testing.
protocol URLSessionTaskType {
    func cancel()
}

extension URLSessionTask: URLSessionTaskType {}


