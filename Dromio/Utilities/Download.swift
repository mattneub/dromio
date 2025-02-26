import Foundation

enum DownloadError: Error {
    case noSuffix
    case ranOutOfTime
}

@MainActor
protocol DownloadType {
    func download(song: SubsonicSong) async throws -> URL
}

@MainActor
final class Download: DownloadType {
    func downloadsDirectory() -> URL {
        URL.cachesDirectory
    }

    init() {
        // TODO: For now, we are emptying the cache on each startup
        let fileManager = FileManager.default
        let contents: [URL] = (try? fileManager.contentsOfDirectory(
            at: downloadsDirectory(),
            includingPropertiesForKeys: []
        )) ?? []
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }

    func download(song: SubsonicSong) async throws -> URL {
        let fileManager = FileManager.default
        guard let suffix = song.suffix else {
            throw DownloadError.noSuffix
        }
        let filename = song.id + "." + suffix
        // check to see if we already have this song cached
        let contents: [URL] = (try? fileManager.contentsOfDirectory(
            at: downloadsDirectory(),
            includingPropertiesForKeys: []
        )) ?? []
        for url in contents {
            if url.lastPathComponent == filename {
                return url
            }
        }
        // we don't have it cached, fetch it
        var url = try await services.requestMaker.download(songId: song.id)
        // rename it
        var rv = URLResourceValues()
        rv.name = filename
        try url.setResourceValues(rv)
        url.deleteLastPathComponent()
        url.appendPathComponent(filename)
        // move it into Downloads and return new URL
        let newURL = downloadsDirectory().appending(path: filename, directoryHint: .notDirectory)
        if let _ = try? fileManager.moveItem(at: url, to: newURL) {
            return newURL
        }
        // if that failed, punt: return the renamed URL so we are playing _something_
        return url
    }
}
