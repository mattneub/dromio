import Foundation

enum PlaylistError: Error {
    case songAlreadyInList
}

/// Protocol expressing the public face of our Playlist class.
protocol PlaylistType: Sendable {
    var list: [SubsonicSong] { get }
    func setList(_ newList: [SubsonicSong])
    func append(_ song: SubsonicSong) throws
    func delete(song: SubsonicSong)
    func move(from fromRow: Int, to toRow: Int)
    func clear()
}

/// Class that represents a playlist. It's just a list of songs, plus the ability to edit the list
/// (set it, append to it, delete a song, move a song, clear the list).
///
/// At the moment, this class represents only the _current_ playlist, i.e. the anonymous "Queue" displayed
/// in the Queue screen of the interface. This is the only thing that can be played. If we ever decide to implement
/// named playlists, the assumptions in this class will break and it will have to be modified.
final class Playlist: PlaylistType {

    /// Source of truth for playlist contents. As mentioned above, we simply assume that we are
    /// the current playlist, because there are no other playlists at the moment.
    var list: [SubsonicSong] {
        get {
            (try? services.persistence.loadCurrentPlaylist()) ?? []
        }
        set {
            try? services.persistence.saveCurrentPlaylist(songList: newValue)
        }
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
