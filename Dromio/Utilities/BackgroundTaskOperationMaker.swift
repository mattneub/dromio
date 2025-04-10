import UIKit

/// Protocol describing a type that is a factory for our BackgroundTaskOperation.
@MainActor
protocol BackgroundTaskOperationMakerType {
    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?
    ) -> any BackgroundTaskOperationType<T>
}

/// Extension allowing `cleanup` to be omitted from the `make` call.
extension BackgroundTaskOperationMakerType {
    func make<T: Sendable>(
        whatToDo: @Sendable @escaping () async throws -> T
    ) -> any BackgroundTaskOperationType<T> {
        return make(whatToDo: whatToDo, cleanup: nil)
    }
}

/// Factory class that makes a BackgroundTaskOperation — wrapped in a protocol, so that
/// a mock version of this class can make a mock version of the BackgroundTaskOperation.
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
