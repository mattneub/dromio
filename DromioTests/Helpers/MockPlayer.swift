@testable import Dromio
import Foundation
import Combine

@MainActor
final class MockPlayer: PlayerType {
    var currentItem = CurrentValueSubject<String?, Never>(nil)
    var url: URL?
    var song: SubsonicSong?
    var methodsCalled = [String]()

    func play(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.song = song
    }

    func playNext(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.song = song
    }

    func clear() {
        methodsCalled.append(#function)
    }
}
