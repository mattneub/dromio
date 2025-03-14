import Foundation

/// Class that functions as a delegate for our download task. It observes the progress of the
/// task and forwards each update to the Networker, where it can be subscribed to.
///
final class DownloadDelegate: NSObject, URLSessionTaskDelegate {
    nonisolated(unsafe) private var observations = Set<NSKeyValueObservation>()

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        let observation = task.progress.observe(\.fractionCompleted, options: [.new]) { _, fraction in
            guard let url = task.originalRequest?.url else {
                return
            }
            guard let id = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems?.first(where: { $0.name == "id" })?.value else {
                return
            }
            Task {
                await services.networker.progress(id: id, fraction: fraction.newValue)
            }
        }
        observations.insert(observation)
    }
}

