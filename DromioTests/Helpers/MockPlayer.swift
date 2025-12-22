@testable import Dromio
import Foundation
import Combine

final class MockPlayer: PlayerType {
    var currentSongIdPublisher = CurrentValueSubject<String?, Never>(nil)
    var playerStatePublisher = CurrentValueSubject<Player.PlayerState, Never>(.empty)
    var url: URL?
    var urls = [URL]()
    var song: SubsonicSong?
    var methodsCalled = [String]()

    func play(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.urls.append(url)
        self.song = song
    }

    func playNext(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.urls.append(url)
        self.song = song
    }

    func clear() {
        methodsCalled.append(#function)
    }

    func backgrounding() {
        methodsCalled.append(#function)
    }

    func foregrounding() {
        methodsCalled.append(#function)
    }

    func playPause() {
        methodsCalled.append(#function)
    }

}
