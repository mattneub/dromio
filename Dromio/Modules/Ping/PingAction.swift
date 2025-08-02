/// Actions sent by the Ping view controller to its processor.
///
enum PingAction: Equatable {
    /// Give the user some choices as to what to do now.
    case choices
    /// The user would like to delete a server.
    case deleteServer
    /// Ping the server, please. The argument is the folder id to restrict to, if any.
    case doPing(Int? = nil)
    /// The app is launching.
    case launch
    /// The user would like to enter offline mode.
    case offlineMode
    /// The user would like to pick a folder.
    case pickFolder
    /// The user would like to pick a server.
    case pickServer
    /// The user would like to re-enter the server info.
    case reenterServerInfo
}
