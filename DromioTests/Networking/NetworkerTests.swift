@testable import Dromio
import Foundation
import Testing

@MainActor
class NetworkerTests {
    let subject = Networker(session: NetworkerTests.session)

    static var session: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    deinit {
        Task { @MainActor in
            MockURLProtocol.requestHandler = nil
        }
    }

    @Test("performRequest: throws if response is not HTTPURLResponse")
    func performRequestWrongResponseType() async throws {
        MockURLProtocol.requestHandler = { request in
            return (URLResponse(), Data())
        }
        await #expect {
            try await subject.performRequest(url: URL(string: "https://www.example.com")!)
        } throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We received a non-HTTPURLResponse.")
        }
    }

    @Test("performRequest: throws if response status code is not 200")
    func performRequestWrongResponseStatusCode() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )
            return (response!, Data())
        }
        await #expect {
            try await subject.performRequest(url: URL(string: "https://www.example.com")!)
        } throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We got a status code 400.")
        }
    }

    @Test("performRequest: returns data if all is well")
    func performRequestReturnsData() async throws {
        let data = "howdy".data(using: .utf8)
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            return (response!, data!)
        }
        let result = try await subject.performRequest(url: URL(string: "https://www.example.com")!)
        #expect(result == data)
    }

}

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
