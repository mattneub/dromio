/// Effects sent by PlaylistProcessor to its presenter.
enum PlaylistEffect: Equatable {
    /// Remove all table view cell selection.
    case deselectAll
    /// The player state has changed. The associated value is the new state.
    case playerState(Player.PlayerState)
    /// A download has progressed. The associated values are the song id and the fraction downloaded.
    case progress(String, Double?)
}
