/// State to be presented by the Ping view controller.
///
struct PingState: Equatable {
    var status: PingStatus = .empty

    /// States that the view can be in.
    enum PingStatus: Equatable {
        case empty // no status (we are looking to see whether we even _have_ a server)
        case unknown // we are about to try to ping
        case success // it worked
        case failure(message: String) // it didn't work
        case choices // we are "at rest"; give the user options on how to proceed
    }
}
