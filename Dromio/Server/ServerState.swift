/// State reflected in the server view controller.
struct ServerState {
    var scheme: ServerAction.Scheme = .http
    var host: String = ""
    var port: String = ""
    var username: String = ""
    var password: String = ""
}
