import Foundation

/// Public face of our Download type.
protocol DownloadType: Actor {
    func download(song: SubsonicSong) async throws -> URL
    func clear()
    func delete(song: SubsonicSong) throws
    func downloadedURL(for song: SubsonicSong) throws -> URL?
    func isDownloaded(song: SubsonicSong) -> Bool
}

/// Actor responsible for requesting and maintaining our downloaded songs.
/// It's an actor so that our interaction with the file manager cannot interfere with
/// stuff going on on the main actor.
///
actor Download: DownloadType {
    /// Function that provides a reference to the file manager, wrapped in a protocol for testing.
    /// By default, the function returns the default file manager, and that is all the app needs.
    var fileManagerProvider: () -> FileManagerType = { FileManager.default }

    /// Method that allows the `fileManagerProvider` function to be replaced. Should not be called
    /// except by a test that needs to mock the file manager.
    /// - Parameter provider: The replacement provider function.
    func setFileManagerProvider(provider: @escaping @Sendable () -> FileManagerType) {
        self.fileManagerProvider = provider
    }

    /// The directory where downloads are stored.
    func downloadsDirectory() -> URL { .cachesDirectory }

    
    /// Download the requested song.
    /// - Parameter song: The song to be downloaded.
    /// - Returns: The URL where the downloaded song is stored in the downloads directory.
    ///
    /// The downloaded data arrives into the temporary directory. There, we rename it using
    /// the song's id plus its original suffix, and move it to downloads directory.
    func download(song: SubsonicSong) async throws -> URL {
        if let url = try downloadedURL(for: song) {
            return url
        }
        // we don't have it cached, fetch it
        var url = try await services.requestMaker.download(songId: song.id)
        // rename it
        let filename = try filename(for: song)
        var rv = URLResourceValues()
        rv.name = filename
        try url.setResourceValues(rv)
        url.deleteLastPathComponent()
        url.appendPathComponent(filename)
        // move it into the downloads directory and return new URL
        let newURL = downloadsDirectory().appending(path: filename, directoryHint: .notDirectory)
        if let _ = try? fileManagerProvider().moveItem(at: url, to: newURL) {
            return newURL
        }
        // if that failed (it shouldn't), punt by returning the renamed URL in temp so we are can play _something_
        return url
    }

    /// Given a song, construct a filename under which to save it in the downloads directory.
    /// The name is built from the song's `id`, because this is unique and stable, and its `suffix`,
    /// because otherwise the song cannot be played. We absolutely must have a suffix, so we throw
    /// if not.
    /// - Parameter song: The song.
    /// - Returns: The filename.
    /// 
    private func filename(for song: SubsonicSong) throws -> String {
        guard let suffix = song.suffix else {
            throw DownloadError.noSuffix
        }
        return song.id + "." + suffix
    }
    
    /// Delete the given song's downloaded data.
    /// - Parameter song: The song.
    func delete(song: SubsonicSong) throws {
        guard let url = try downloadedURL(for: song) else { return }
        try fileManagerProvider().removeItem(at: url)
    }

    /// Remove all downloaded songs, both in the downloads directory and in the temp directory.
    func clear() {
        clear(directory: downloadsDirectory())
        clear(directory: URL.temporaryDirectory)
    }
    
    /// Clear the contents of the given directory.
    /// - Parameter directory: The directory.
    private func clear(directory: URL) {
        let fileManager = fileManagerProvider()
        let contents: [URL] = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
    
    /// Given a song, return the URL to which it has been downloaded in the downloads directory,
    /// or nil if the song is not found in the downloads directory.
    /// - Parameter song: The song.
    /// - Returns: Its URL, or nil.
    ///
    func downloadedURL(for song: SubsonicSong) throws -> URL? {
        let filename = try filename(for: song)
        let contents: [URL] = (try? fileManagerProvider().contentsOfDirectory(
            at: downloadsDirectory(),
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []
        for url in contents {
            if url.lastPathComponent == filename {
                return url
            }
        }
        return nil
    }

    /// Simplified wrapper for `downloadedURL` when all we _really_ want to know is whether the
    /// song has been downloaded (i.e. we don't actually need its URL).
    /// - Parameter song: The song.
    /// - Returns: A Bool. If there's a problem, returns `false`.
    /// 
    func isDownloaded(song: SubsonicSong) -> Bool {
        do {
            return try downloadedURL(for: song) != nil
        } catch {
            return false
        }
    }
}

/// Errors that our Download can throw.
enum DownloadError: Error {
    case noSuffix
    case ranOutOfTime
}

