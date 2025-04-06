/// Effects sent by the AlbumProcessor to its presenter.
enum AlbumEffect {
    /// Waggle the playlist icon.
    case animatePlaylist
    /// Remove any cell selection.
    case deselectAll
    /// Scroll the table view to the top, hiding the search bar if there is one
    case scrollToZero
    /// Ensure that the search controller exists and is configured.
    case setUpSearcher
}
