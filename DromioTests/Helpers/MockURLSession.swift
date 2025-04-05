@testable import Dromio
import Foundation

@MainActor
final class MockURLSession: URLSessionType {
    var methodsCalled = [String]()
    var data = Data()
    var urlResponse = URLResponse()
    var url = URL(string: "file://dummy")!
    var tasks = [MockURLSessionTask(), MockURLSessionTask()]

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

@MainActor
final class MockURLSessionTask: URLSessionTaskType {
    var methodsCalled = [String]()

    func cancel() {
        methodsCalled.append(#function)
    }
}
