import Foundation

@MainActor
protocol PlaylistType {
    var list: [SubsonicSong] { get set }
    func append(_ song: SubsonicSong)
}

@MainActor
final class Playlist: PlaylistType {
    var list = [SubsonicSong]()

    func append(_ song: SubsonicSong) {
        list.append(song)
    }
}
