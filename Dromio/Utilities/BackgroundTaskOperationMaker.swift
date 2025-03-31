import UIKit

@MainActor
protocol BackgroundTaskOperationMakerType {
    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?
    ) -> any BackgroundTaskOperationType<T>
}

extension BackgroundTaskOperationMakerType {
    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T
    ) -> any BackgroundTaskOperationType<T> {
        return make(whatToDo: whatToDo, cleanup: nil)
    }
}

@MainActor
final class BackgroundTaskOperationMaker: BackgroundTaskOperationMakerType {
    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?
    ) -> any BackgroundTaskOperationType<T> {
        return BackgroundTaskOperation<T>(
            whatToDo: whatToDo,
            cleanup: cleanup,
            application: UIApplication.shared
        )
    }
}
