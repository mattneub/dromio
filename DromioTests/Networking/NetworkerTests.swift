@testable import Dromio
import Foundation
import Testing

@MainActor
class NetworkerTests {
    var subject: Networker!

    lazy var session: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    init() {
        subject = Networker(session: session)
    }

    @Test("ping: with a bad response status returns false")
    func pingBadResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let response: HTTPURLResponse = .init(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let result = await subject.ping()
        #expect(!result)
    }

    @Test("ping: with a good response status but bad json returns false")
    func pingGoodResponseBadJson() async throws {
        let data = try! JSONEncoder().encode(["what": "theheck"])
        MockURLProtocol.requestHandler = { request in
            let response: HTTPURLResponse = .init(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        let result = await subject.ping()
        #expect(!result)
    }

    @Test("ping: with a good response status and good json returns true")
    func pingGoodResponseGoodJson() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "thing",
                serverVersion: "1",
                openSubsonic: true,
                error: nil
            )
        )
        let data = try! JSONEncoder().encode(payload)
        MockURLProtocol.requestHandler = { request in
            let response: HTTPURLResponse = .init(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        let result = await subject.ping()
        #expect(result)
    }

    @Test("ping: with a good response status and good json but not ok status returns false")
    func pingGoodResponseGoodJsonBadStatus() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "failed",
                version: "1",
                type: "thing",
                serverVersion: "1",
                openSubsonic: true,
                error: .init(code: -1, message: "Oops")
            )
        )
        let data = try! JSONEncoder().encode(payload)
        MockURLProtocol.requestHandler = { request in
            let response: HTTPURLResponse = .init(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        let result = await subject.ping()
        #expect(!result)
    }


    deinit {
        Task { @MainActor in
            MockURLProtocol.requestHandler = nil
        }
    }
}

@MainActor
class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

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
