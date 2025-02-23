import Foundation

/// Actions sent by AlbumViewController to AlbumProcessor.
enum AlbumAction: Equatable {
    /// The view controller is ready for its data.
    case initialData
    /// The user tapped a song.
    case tapped(SubsonicSong)
}
