/// Actions sent by the Ping view controller to its processor.
///
enum PingAction: Equatable {
    /// Ping the server, please.
    case doPing
    /// The user would like to re-enter the server info.
    case reenterServerInfo
}
