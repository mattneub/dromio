import Foundation

@MainActor
class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    static var requestHandler: (@Sendable (URLRequest) throws -> (URLResponse, Data))?

    override func startLoading() {
        Task {
            if let (response, data) = try? await MockURLProtocol.requestHandler?(request) {
                print("mock url protocol is handling this")
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } else {
                fatalError("wtf")
            }
        }
    }

    override func stopLoading() {}
}
