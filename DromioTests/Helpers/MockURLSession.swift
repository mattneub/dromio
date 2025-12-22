@testable import Dromio
import Foundation

final class MockURLSession: URLSessionType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var data = Data()
    nonisolated(unsafe) var urlResponse = URLResponse()
    nonisolated(unsafe) var url = URL(string: "file://dummy")!
    nonisolated(unsafe) var tasks = [MockURLSessionTask(), MockURLSessionTask()]

    func allTasks() async -> [any URLSessionTaskType] {
        methodsCalled.append(#function)
        return tasks
    }
    
    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
        methodsCalled.append(#function)
        return (data, urlResponse)
    }
    
    func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
        methodsCalled.append(#function)
        return (url, urlResponse)
    }
}

final class MockURLSessionTask: URLSessionTaskType {
    var methodsCalled = [String]()

    func cancel() {
        methodsCalled.append(#function)
    }
}
