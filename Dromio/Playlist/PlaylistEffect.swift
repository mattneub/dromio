/// Effects sent by PlaylistProcessor to its presenter.
enum PlaylistEffect: Equatable {
    case deselectAll
    case progress(String, Double?)
}
