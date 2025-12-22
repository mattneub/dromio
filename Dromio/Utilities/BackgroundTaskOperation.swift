import UIKit

/// Protocol describing the public face of our BackgroundTaskOperation, so we can mock it for testing.
protocol BackgroundTaskOperationType<T> {
    associatedtype T: Sendable
    init(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())?,
        application: ApplicationType
    )
    func start() async throws -> T
}

/// Class that encapsulates the boilerplate needed to ask for an extra 30 seconds (or so) of time
/// just in case the app goes into the background while we are doing some time-consuming operation
/// that we don't want interrupted if we can help it.
final class BackgroundTaskOperation<T: Sendable>: BackgroundTaskOperationType {
    /// The time-consuming operation.
    private let whatToDo: @Sendable () async throws -> T

    /// Optionally, what to do if the operation is interrupted.
    private let cleanup: (@Sendable () async throws -> ())?

    private let application: any ApplicationType

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
    ///   - application: The application, typed through a protocol for testing purposes.
    init(
        whatToDo: @Sendable @escaping () async throws -> T,
        cleanup: (@Sendable () async throws -> ())? = nil,
        application: ApplicationType = UIApplication.shared
    ) {
        self.whatToDo = whatToDo
        self.cleanup = cleanup
        self.application = application
    }

    /// Begin the time-consuming operation.
    /// - Returns: The value returned by the `whatToDo` function.
    func start() async throws -> T {
        bti = application.beginBackgroundTask { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                try? await cleanup?()
                if bti != .invalid {
                    application.endBackgroundTask(bti)
                }
            }
        }
        do {
            let result = try await whatToDo()
            if bti != .invalid {
                application.endBackgroundTask(bti)
            }
            return result
        } catch {
            return try await Task { @MainActor in // this way we can throw and return nothing
                try await cleanup?()
                if bti != .invalid {
                    application.endBackgroundTask(bti)
                }
                throw error
            }.value
        }
    }
}

