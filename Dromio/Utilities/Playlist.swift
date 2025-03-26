import Foundation

enum PlaylistError: Error {
    case songAlreadyInList
}

@MainActor
protocol PlaylistType: Sendable {
    var list: [SubsonicSong] { get set }
    func append(_ song: SubsonicSong) throws
    func delete(song: SubsonicSong)
    func clear()
}

@MainActor
final class Playlist: PlaylistType {
    let persistenceKey: PersistenceKey

    /// Source of truth for playlist contents.
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
    
    /// Delete the given song from the list.
    /// - Parameter song: The song.
    func delete(song: SubsonicSong) {
        guard let index = list.firstIndex(where: { $0.id == song.id }) else {
            return
        }
        list.remove(at: index)
    }

    /// Clear the list.
    func clear() {
        list.removeAll()
    }
}
