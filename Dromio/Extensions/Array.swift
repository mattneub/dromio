import Foundation

extension Array where Element == SubsonicAlbum {
    /// Return a sorted version of an array of SubsonicAlbum, in the order in which we wish it
    /// displayed in the interface (in the Albums screen). Basically this order is alphabetical
    /// by `name`, sorted in the way the Finder would do it.
    ///
    /// Fortunately, a SubsonicAlbum has a `sortedName` property which is supposed to help us
    /// with this very task. Unfortunately, there's a bug: `getAlbumList2` is returning the
    /// album list _without_ any values in the `sortedName` (it is an empty string).
    /// So for now we are ignoring the incoming `sortedName` and just writing into that property
    /// ourselves, for convenience.
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
        // That's it: in a single pass, we've set the sortName of every album.
        // Now sort the albums by that sortName, "as the Finder would do it".
        .sorted { $0.sortName!.localizedStandardCompare($1.sortName!) == .orderedAscending }
    }
}

