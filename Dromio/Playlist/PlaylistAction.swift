import Foundation

/// Actions sent by PlaylistViewController to PlaylistProcessor.
enum PlaylistAction: Equatable {
    /// Clear the list.
    case clear
    /// Delete the list entry at the given row.
    case delete(Int)
    /// The view controller is ready for its data.
    case initialData
    /// The user tapped the jukebox button.
    case jukeboxButton
    /// The user tapped the playpause button.
    case playPause
    /// The user tapped a song.
    case tapped(SubsonicSong)
}
