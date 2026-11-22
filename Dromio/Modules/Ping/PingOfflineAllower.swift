import Foundation

/// Public face of our ping offline allower.
protocol PingOfflineAllowerType {
    func canShowOfflineModeButton() async -> Bool
}

/// Small object embodying the logic of whether the user can enter offline mode.
/// Moving the logic into a separate object from the processor simplifies testing.
struct PingOfflineAllower: PingOfflineAllowerType {
    func canShowOfflineModeButton() async -> Bool {
        // intersect the current playlist with downloads
        var intersection = [URL?]()
        for song in services.currentPlaylist.list {
            intersection.append(try? await services.download.downloadedURL(for: song))
        }
        return !intersection.compactMap({$0}).isEmpty
    }
}
