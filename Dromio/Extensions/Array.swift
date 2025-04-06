import Foundation

extension Array where Element == SubsonicAlbum {
    /// Return a sorted version of an array of SubsonicAlbum, in the order in which we wish it
    /// displayed in the interface (in the Albums screen). Basically this order is alphabetical
    /// by `name`, sorted in the way the Finder would do it.
    ///
    /// A SubsonicAlbum has a `sortedName` property which is supposed to help us
    /// with this very task, but I don't completely agree with that order. So we simply
    /// misuse that property as a scratchpad.
    ///
    var sorted: [SubsonicAlbum] {
        self.map { album in
            var album = album
            // lowercase the sortName from the name and strip out diacritics
            album.sortName = album.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            // strip "little" initial words from the sortName
            for word in ["a ", "an ", "the ", "de ", "d'", "d’"] {
                if album.sortName!.hasPrefix(word) {
                    album.sortName = String(album.sortName!.dropFirst(word.count))
                    break
                }
            }
            return album
        }
        // That's it: in a single pass, we've set the sortName of every album.
        // Now sort the albums by that sortName, "as the Finder would do it".
        .sorted { $0.sortName!.localizedStandardCompare($1.sortName!) == .orderedAscending }
    }
}

extension Array where Element == SubsonicArtist {
    /// Return a sorted version of an array of SubsonicArtist, in the order in which we wish it
    /// displayed in the interface (in the Artists / Composers screen). Basically this order is alphabetical
    /// by `name`, sorted in the way the Finder would do it.
    ///
    /// A SubsonicArtist has a `sortedName` property which is supposed to help us
    /// with this very task, but I don't completely agree with that order. So we simply
    /// misuse that property as a scratchpad.
    ///
    var sorted: [SubsonicArtist] {
        self.map { artist in
            var artist = artist
            // lowercase the sortName from the name and strip out diacritics
            artist.sortName = artist.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            // strip "little" initial words from the sortName
            for word in ["a ", "an ", "the ", "de ", "d'", "d’"] {
                if artist.sortName!.hasPrefix(word) {
                    artist.sortName = String(artist.sortName!.dropFirst(word.count))
                    break
                }
            }
            return artist
        }
        // That's it: in a single pass, we've set the sortName of every artist.
        // Now sort the artists by that sortName, "as the Finder would do it".
        .sorted { $0.sortName!.localizedStandardCompare($1.sortName!) == .orderedAscending }
    }
}

extension Array where Element == SubsonicSong {
    /// Given a song, find it in the list and extract a sequence from that song to the
    /// end of the playlist.
    /// - Parameter song: The song to start with. Should be in the current playlist.
    /// - Returns: The sequence (array) of songs.
    ///
    func buildSequence(startingWith song: SubsonicSong) -> [SubsonicSong] {
        guard let start = firstIndex(where: { $0.id == song.id }) else {
            return []
        }
        return Array(self[start...])
    }
}

