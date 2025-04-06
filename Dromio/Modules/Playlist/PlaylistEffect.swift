/// Effects sent by PlaylistProcessor to its presenter.
enum PlaylistEffect: Equatable {
    case deselectAll
    case playerState(Player.PlayerState)
    case progress(String, Double?)
}
