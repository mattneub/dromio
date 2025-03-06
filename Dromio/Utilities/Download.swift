import Foundation

enum DownloadError: Error {
    case noSuffix
    case ranOutOfTime
}

/// Public face of our Download type.
protocol DownloadType: Actor {
    func download(song: SubsonicSong) async throws -> URL
    func clear()
}

/// Actor responsible for requesting and maintaining our downloaded songs.
/// It's an actor so that our interaction with the file manager cannot interfere with
/// stuff going on on the main actor.
///
actor Download: DownloadType {
    /// The directory where downloads are stored.
    func downloadsDirectory() -> URL { .cachesDirectory }

    
    /// Download the requested song.
    /// - Parameter song: The song to be downloaded.
    /// - Returns: The URL where the downloaded song is stored in the downloads directory.
    ///
    /// The downloaded data goes into the temporary directory. There, we rename it using
    /// the song's id plus its original suffix. Thus we can always access a downloaded song.
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
        // move it into the downloads directory and return new URL
        let newURL = downloadsDirectory().appending(path: filename, directoryHint: .notDirectory)
        if let _ = try? fileManager.moveItem(at: url, to: newURL) {
            return newURL
        }
        // if that failed (it shouldn't), punt by returning the renamed URL so we are can play _something_
        return url
    }

    /// Remove all downloaded songs, both in the downloads directory and in the temp directory.
    func clear() {
        let fileManager = FileManager.default
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: downloadsDirectory(),
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: URL.temporaryDirectory,
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
