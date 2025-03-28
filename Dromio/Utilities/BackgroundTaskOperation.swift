import UIKit

// TODO: Work out how to test this, presumably by mocking the application

/// Class that encapsulates the boilerplate needed to ask for an extra 30 seconds (or so) of time
/// just in case the app goes into the background while we are doing some time-consuming operation
/// that we don't want interrupted if we can help it.
@MainActor
final class BackgroundTaskOperation<T: Sendable> {
    /// The time-consuming operation.
    private let whatToDo: @Sendable () async throws -> T

    /// Optionally, what to do if the operation is interrupted.
    private let cleanup: (@Sendable () async throws -> ())?

    /// The identifier handed to us by the system; to be used in order to signal to the system
    /// that the operation is over, or that we understand we have been interrupted. Basically this
    /// is a way of making sure that our call to `endBackgroundTask` corresponds to our call to
    /// `beginBackgroundTask`, i.e. it is the same task. Thus it is perfectly fine to instantiate
    /// this class multiple times and run multiple operations, simultaneously.
    private var bti: UIBackgroundTaskIdentifier = .invalid

    /// Initializer.
    /// - Parameters:
    ///   - whatToDo: The time-consuming operation. It may return a value, whose type will be the
    ///       resolution of the class's generic type. Ideally, this operation should not require
    ///       more than about 30 seconds; if it does, and if the app went into the background as
    ///       soon as the operation started, the operation will probably be interrupted by
    ///       the system.
    ///   - cleanup: Optionally, what to do if the operation is interrupted.
    init(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())? = nil
    ) {
        self.whatToDo = whatToDo
        self.cleanup = cleanup
    }

    /// Begin the time-consuming operation.
    /// - Returns: The value returned by the `whatToDo` function.
    func start() async throws -> T {
        bti = UIApplication.shared.beginBackgroundTask {
            Task { @MainActor in
                try? await self.cleanup?()
                UIApplication.shared.endBackgroundTask(self.bti)
            }
        }
        do {
            guard bti != .invalid else { throw NSError(domain: "what", code: 0) }
            let result = try await whatToDo()
            UIApplication.shared.endBackgroundTask(bti)
            return result
        } catch {
            Task { @MainActor in
                try await self.cleanup?()
            }
            UIApplication.shared.endBackgroundTask(self.bti)
            throw error
        }
    }
}

