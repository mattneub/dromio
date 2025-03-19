@testable import Dromio
import Foundation

actor MockDownload: DownloadType {

    var urlToReturn: URL = URL(string: "file://temp/stuff")!
    var song: SubsonicSong?
    var methodsCalled = [String]()
    nonisolated(unsafe) var bools: [String: Bool] = [:]

    func download(song: SubsonicSong) async throws -> URL {
        methodsCalled.append(#function)
        self.song = song
        return urlToReturn
    }

    func clear() {
        methodsCalled.append(#function)
    }

    func downloadedURL(for song: Dromio.SubsonicSong) throws -> URL? {
        methodsCalled.append(#function)
        self.song = song
        if bools[song.id] == true { return URL(string: "file://yoho")! }
        else { return nil }
    }

}
