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

    @Test("ping: with a nil URL throws with message")
    func pingBadURL() {
        // TODO: how to test this?
    }

    @Test("ping: with a non http url response throws with message")
    func pingBadResponseType() {
        // TODO: how to test this?
    }

    @Test("ping: with a non-200 http url response status code throws with message")
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
        await #expect(performing: {
            try await subject.ping()
        }, throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We got a status code 400.")
        })
    }

    @Test("ping: with a good response status but not navidrome server throws with message")
    func pingGoodResponseBadServer() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "thing", // *
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
        await #expect(performing: {
            try await subject.ping()
        }, throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("The server does not appear to be a Navidrome server.")
        })
    }

    @Test("ping: with a good response status but bad json throws with message")
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
        await #expect(performing: {
            try await subject.ping()
        }, throws: { error in
            let error = try #require(error as? DecodingError)
            return error.localizedDescription == "The data couldn’t be read because it is missing."
        })
    }

    @Test("ping: with a good response status and good json does not throw")
    func pingGoodResponseGoodJson() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1", // we are not yet checking this
                type: "navidrome",
                serverVersion: "1", // we are not yet checking this either
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
        try await subject.ping()
    }

    @Test("ping: with a good response status and good json but not ok status throws with server error message")
    func pingGoodResponseGoodJsonBadStatus() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "failed",
                version: "1",
                type: "navidrome",
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
        await #expect(performing: {
            try await subject.ping()
        }, throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("Oops")
        })
    }

    @Test("ping: with a good response status and good json but not ok status throws and no server error message throws a made-up message")
    func pingGoodResponseGoodJsonBadStatusNoServerError() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "failed",
                version: "1",
                type: "navidrome",
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
        await #expect(performing: {
            try await subject.ping()
        }, throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We got a failed status from the Navidrome server.")
        })
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
