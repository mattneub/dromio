@testable import Dromio
import Foundation
import Combine
import Testing
import WaitWhile

struct NetworkerTests {
    let subject = Networker(session: NetworkerTests.session)

    static var session: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    @Test("default session is URLSession with config request timeout 10")
    func session() throws {
        let subject = Networker()
        let session = try #require(subject.session as? URLSession)
        let config = session.configuration
        #expect(config.timeoutIntervalForRequest == 10)
    }

    @Test("clear: resets the fraction of the progress publisher if it is less than 1")
    func clear() async {
        do {
            subject.progress(id: "-1", fraction: 1)
            await subject.clear()
            #expect(subject.progress.value.fraction == 1)
            #expect(subject.progress.value.id == "-1")
        }
        do {
            subject.progress(id: "-1", fraction: 0.9)
            await subject.clear()
            #expect(subject.progress.value.fraction == 0)
            #expect(subject.progress.value.id == "-1")
        }
    }

    @Test("clear: cancels session tasks")
    func clearCancelsTasks() async throws {
        let mockSession = MockURLSession()
        let subject = Networker(session: mockSession)
        mockSession.tasks = [MockURLSessionTask(), MockURLSessionTask()]
        await subject.clear()
        for task in mockSession.tasks {
            #expect(task.methodsCalled == ["cancel()"])
        }
    }

    @Test("performRequest: throws if response is not HTTPURLResponse")
    func performRequestWrongResponseType() async throws {
        MockURLProtocol.requestHandler = { request in
            return (URLResponse(), Data())
        }
        await #expect {
            try await self.subject.performRequest(url: URL(string: "https://www.example.com")!)
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
            try await self.subject.performRequest(url: URL(string: "https://www.example.com")!)
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

    @Test("performDownloadRequest: throws if response is not HTTPURLResponse", .mockBackgroundTask)
    func performDownloadRequestWrongResponseType() async throws {
        MockURLProtocol.requestHandler = { request in
            return (URLResponse(), Data())
        }
        await #expect {
            try await self.subject.performDownloadRequest(url: URL(string: "https://www.example.com")!)
        } throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We received a non-HTTPURLResponse.")
        }
        #expect(try operatedOnBackgroundTask() == 1)
    }

    @Test("performDownloadRequest: throws if response status code is not 200", .mockBackgroundTask)
    func performDownloadRequestWrongResponseStatusCode() async throws {
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
            try await self.subject.performDownloadRequest(url: URL(string: "https://www.example.com")!)
        } throws: { error in
            let error = try #require(error as? NetworkerError)
            return error == .message("We got a status code 400.")
        }
        #expect(try operatedOnBackgroundTask() == 1)
    }

    @Test("performDownloadRequest: returns url if all is well, url contains data", .mockBackgroundTask)
    func performDownloadRequestReturnsURL() async throws {
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
        let url = try await subject.performDownloadRequest(url: URL(string: "https://www.example.com")!)
        let resultData = try Data(contentsOf: url)
        #expect(resultData == data)
        #expect(try operatedOnBackgroundTask() == 1)
    }

    @Test("progress: sends value to passthru subject")
    func progress() async throws {
        var pipeline: AnyCancellable?
        var result: (id: String, fraction: Double?)?
        pipeline = subject.progress.sink { result = $0 }
        subject.progress(id: "1", fraction: 0.5)
        #expect(result?.id == "1")
        #expect(result?.fraction == 0.5)
    }

    func operatedOnBackgroundTask() throws -> Int {
        let mockBackgroundTaskOperationMaker = try #require(services.backgroundTaskOperationMaker as? MockBackgroundTaskOperationMaker)
        let mockBackgroundTaskOperation = try #require(
            mockBackgroundTaskOperationMaker.mockBackgroundTaskOperation as? MockBackgroundTaskOperation<(URL, URLResponse)>
        )
        #expect(mockBackgroundTaskOperation.methodsCalled == ["start()"])
        return mockBackgroundTaskOperationMaker.timesCalled
    }
}
