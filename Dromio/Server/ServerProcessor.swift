import Foundation

/// Processor containing the logic for the server view controller.
@MainActor
final class ServerProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<Void, ServerState>)?

    weak var delegate: (any ServerDelegate)?

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
                coordinator?.dismissToPing()
                delegate?.userEdited(serverInfo: serverInfo)
            } catch {
                coordinator?.showAlert(title: "Error", message: error.issue)
            }
        }
    }
}

@MainActor
protocol ServerDelegate: AnyObject {
    func userEdited(serverInfo: ServerInfo)
}
