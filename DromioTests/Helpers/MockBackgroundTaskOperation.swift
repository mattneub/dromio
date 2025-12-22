@testable import Dromio
import UIKit

final class MockBackgroundTaskOperation<T: Sendable>: BackgroundTaskOperationType {
    var methodsCalled = [String]()
    var whatToDo: @Sendable () async throws -> T
    init(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?,
        application: ApplicationType
    ) {
        self.whatToDo = whatToDo
    }

    func start() async throws -> T {
        methodsCalled.append(#function)
        return try await whatToDo()
    }
}

final class MockBackgroundTaskOperationMaker: nonisolated BackgroundTaskOperationMakerType {
    var mockBackgroundTaskOperation: (any BackgroundTaskOperationType)?
    var timesCalled = 0

    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?
    ) -> any BackgroundTaskOperationType<T> {
        timesCalled += 1
        mockBackgroundTaskOperation = MockBackgroundTaskOperation(
            whatToDo: whatToDo,
            cleanup: nil,
            application: MockApplication()
        )
        return mockBackgroundTaskOperation as! MockBackgroundTaskOperation
    }
}
