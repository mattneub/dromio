/// State to be presented by the Ping view controller.
///
struct PingState: Equatable {
    /// Whether the ping succeeded or failed and, if it failed, a message to display.
    var success: PingResult = .failure(message: "")

    enum PingResult: Equatable {
        case success
        case failure(message: String)
    }
}
