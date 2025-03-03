/// Messages from the server processor to its presenter.
enum ServerEffect: Equatable {
    case alertWithMessage(String)
}
