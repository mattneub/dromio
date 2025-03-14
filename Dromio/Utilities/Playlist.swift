import Foundation

enum PlaylistError: Error {
    case songAlreadyInList
}

@MainActor
protocol PlaylistType: Sendable {
    var list: [SubsonicSong] { get set }
    func append(_ song: SubsonicSong) throws
    func clear()
}

@MainActor
final class Playlist: PlaylistType {
    let persistenceKey: PersistenceKey

    var list: [SubsonicSong] {
        get {
            (try? services.persistence.loadSongList(key: persistenceKey)) ?? []
        }
        set {
            try? services.persistence.save(songList: newValue, key: persistenceKey)
        }
    }

    init(persistenceKey: PersistenceKey = .currentPlaylist) {
        self.persistenceKey = persistenceKey
    }

    /// Append the given song to the end of the list; but throw if the song is already in the list.
    /// - Parameter song: Song to append.
    func append(_ song: SubsonicSong) throws {
        guard !list.contains(song) else {
            throw PlaylistError.songAlreadyInList
        }
        list.append(song)
    }

    /// Clear the list.
    func clear() {
        list.removeAll()
    }
}
