/// Effects sent by the AlbumProcessor to its presenter.
enum AlbumEffect: Equatable {
    /// Animate the given song's cell flying into the playlist icon.
    case animate(song: SubsonicSong)
    /// Waggle the playlist icon.
    case animatePlaylist
    /// Remove any cell selection.
    case deselectAll
    /// Scroll the table view to the top.
    case scrollToZero
}
