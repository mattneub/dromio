@testable import Dromio
import Testing
import Foundation
import WaitWhile

struct DownloadDelegateTests {
    let subject = DownloadDelegate()
    let networker = MockNetworker()

    static var session: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    init() {
        services.networker = networker
    }

    @Test("urlsessionDidCreateTask: observes progress, passes it to networker")
    func didCreateTask() async {
        let task = MockTask()
        task.originalRequest = URLRequest(url: URL(string: "http://www.example.com?id=1")!)
        subject.urlSession(Self.session, didCreateTask: task)
        task.doProgress(0.5)
        await #while(networker.methodsCalled.isEmpty)
        #expect(networker.methodsCalled.contains("progress(id:fraction:)"))
        #expect(networker.id == "1")
        #expect(networker.fraction == 0.5)
    }
}

nonisolated
final class MockTask: URLSessionTask, @unchecked Sendable {
    override init() { super.init() } // deprecated but what else can we do?
    var _progress = Progress(totalUnitCount: 100)
    override var progress: Progress {
        get { _progress }
        set { _progress = newValue }
    }
    var _originalRequest = URLRequest(url: URL(string: "www.example.com")!)
    override var originalRequest: URLRequest {
        get { _originalRequest }
        set { _originalRequest = newValue }
    }
    func doProgress(_ fraction: Double) {
        progress.completedUnitCount = Int64(fraction * 100)
    }
}

