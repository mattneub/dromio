import Foundation

enum PlaylistError: Error {
    case songAlreadyInList
}

@MainActor
protocol PlaylistType: Sendable {
    var list: [SubsonicSong] { get }
    func setList(_ newList: [SubsonicSong])
    func append(_ song: SubsonicSong) throws
    func delete(song: SubsonicSong)
    func move(from fromRow: Int, to toRow: Int)
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
            print(list.map { $0.title })
        }
    }

    init(persistenceKey: PersistenceKey = .currentPlaylist) {
        self.persistenceKey = persistenceKey
    }
    
    /// Set the entire list to the given list.
    /// - Parameter newList: The new list of songs.
    func setList(_ newList: [SubsonicSong]) {
        list = newList
    }

    /// Append the given song to the end of the list; but throw if the song is already in the list.
    /// - Parameter song: Song to append.
    func append(_ song: SubsonicSong) throws {
        guard !list.contains(where: { $0.id == song.id }) else {
            throw PlaylistError.songAlreadyInList
        }
        list.append(song)
    }
    
    /// Delete the given song from the list.
    /// - Parameter song: The song.
    func delete(song: SubsonicSong) {
        print("playlist delete")
        guard let index = list.firstIndex(where: { $0.id == song.id }) else {
            return
        }
        list.remove(at: index)
    }
    
    /// Move the song from the given row to the given row.
    /// - Parameters:
    ///   - fromRow: The row to move from.
    ///   - toRow: The row to move to.
    func move(from fromRow: Int, to toRow: Int) {
        var songs = list
        guard fromRow < songs.count else { return }
        guard toRow < songs.count else { return }
        let song = songs.remove(at: fromRow)
        songs.insert(song, at: toRow)
        list = songs
    }

    /// Clear the list.
    func clear() {
        list.removeAll()
    }
}
