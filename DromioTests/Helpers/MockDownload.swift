@testable import Dromio
import Foundation

@MainActor
final class MockDownload: DownloadType {
    var urlToReturn: URL = URL(string: "http://example.com")!
    var song: SubsonicSong?
    var methodsCalled = [String]()

    func download(song: SubsonicSong) async throws -> URL {
        methodsCalled.append(#function)
        self.song = song
        return urlToReturn
    }

    func clear() {
        methodsCalled.append(#function)
    }
}
