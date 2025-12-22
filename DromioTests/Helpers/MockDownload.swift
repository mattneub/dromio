@testable import Dromio
import Foundation

actor MockDownload: DownloadType {
    nonisolated(unsafe) var urlToReturn: URL = URL(string: "file://temp/stuff")!
    nonisolated(unsafe) var song: SubsonicSong?
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var bools: [String: Bool] = [:]

    func download(song: SubsonicSong) async throws -> URL {
        methodsCalled.append(#function)
        self.song = song
        return urlToReturn
    }

    func delete(song: SubsonicSong) throws {
        methodsCalled.append(#function)
        self.song = song
    }

    func clear() {
        methodsCalled.append(#function)
    }

    func downloadedURL(for song: SubsonicSong) throws -> URL? {
        methodsCalled.append(#function)
        self.song = song
        if bools[song.myId] == true {
            return URL(string: "file://yoho")!
        } else {
            return nil
        }
    }

    func isDownloaded(song: SubsonicSong) -> Bool {
        return bools[song.myId] ?? false
    }

}
