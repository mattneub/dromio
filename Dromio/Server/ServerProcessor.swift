import Foundation

/// Processor containing the logic for the server view controller.
@MainActor
final class ServerProcessor: Processor {
    var presenter: (any Presenter<ServerState>)?

    /// Sometimes we want to maintain state without presenting, so this temporary toggle lets us
    /// mutate the state without presenting.
    var noPresentation = false
    var state = ServerState() {
        didSet {
            if noPresentation {
                noPresentation = false
            } else {
                presenter?.present(state)
            }
        }
    }

    func receive(_ action: ServerAction) async {
        switch action {
        case .schemeChanged(let scheme):
            noPresentation = true
            state.scheme = scheme
        case .textFieldChanged(let field, let text):
            let fieldPath: WritableKeyPath<ServerState, String> = switch field {
            case .host: \.host
            case .password: \.password
            case .port: \.port
            case .username: \.username
            }
            noPresentation = true
            state[keyPath: fieldPath] = text
        case .done:
            do {
                let serverInfo = try ServerInfo.init(
                    scheme: state.scheme == .http ? "http" : "https",
                    host: state.host,
                    port: state.port,
                    username: state.username,
                    password: state.password
                )
                try services.persistence.save(servers: [serverInfo])
                services.urlMaker.currentServerInfo = serverInfo
            } catch let error as ServerInfo.ValidationError {
                let issue: String = switch error {
                case .hostEmpty: "The host cannot be empty."
                case .invalidURL: "A valid URL could not be constructed."
                case .passwordEmpty: "The password cannot be empty."
                case .portEmpty: "The port cannot be empty."
                case .portNotNumber: "The port must be a number (an integer)."
                case .usernameEmpty: "The username cannot be empty."
                case .schemeInvalid: "The scheme must be http or https."
                }
                await (presenter as? any Receiver<ServerEffect>)?.receive(.alertWithMessage(issue))
            } catch {}
        }
    }
}
