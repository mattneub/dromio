import Foundation

/// Actions sent by PlaylistViewController to PlaylistProcessor.
enum PlaylistAction: Equatable {
    /// The view controller is ready for its data.
    case initialData
    /// The user tapped a song.
    case tapped(SubsonicSong)
}
