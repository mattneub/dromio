import Foundation

/// Actions sent by AlbumViewController or AlbumDataSourceDelegate to its processor.
enum AlbumAction: Equatable {
    /// The view controller is ready for its data.
    case initialData
    /// The user tapped a song.
    case tapped(SubsonicSong)
    /// The user would like to view the playlist.
    case showPlaylist
}
