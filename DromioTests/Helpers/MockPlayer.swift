@testable import Dromio
import Foundation

@Observable final class MockPlayer: PlayerType {
    var currentSongIdPublisher: String?
    var playerStatePublisher: Player.PlayerState = .empty
    var url: URL?
    var urls = [URL]()
    var song: SubsonicSong?
    var songs = [SubsonicSong]()
    var methodsCalled = [String]()
    var seconds: Double?

    func play(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.urls.append(url)
        self.song = song
        self.songs.append(song)
        self.seconds = nil
    }

    func play(url: URL, song: SubsonicSong, seconds: Double?) {
        methodsCalled.append(#function)
        self.url = url
        self.urls.append(url)
        self.song = song
        self.songs.append(song)
        self.seconds = seconds
    }

    func playNext(url: URL, song: SubsonicSong) {
        methodsCalled.append(#function)
        self.url = url
        self.urls.append(url)
        self.song = song
        self.songs.append(song)
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
