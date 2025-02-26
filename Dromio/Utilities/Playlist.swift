import Foundation

enum PlaylistError: Error {
    case songAlreadyInList
}

@MainActor
protocol PlaylistType {
    var list: [SubsonicSong] { get set }
    func append(_ song: SubsonicSong) throws
}

@MainActor
final class Playlist: PlaylistType {
    var list = [SubsonicSong]()

    func append(_ song: SubsonicSong) throws {
        guard !list.contains(song) else {
            throw PlaylistError.songAlreadyInList
        }
        list.append(song)
    }
}
