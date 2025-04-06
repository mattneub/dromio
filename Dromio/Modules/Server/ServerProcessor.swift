import Foundation

/// Processor containing the logic for the server view controller.
@MainActor
final class ServerProcessor: Processor {
    /// Reference to the coordinator, set by the coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// Reference to the presenter, set by the coordinator on creation.
    weak var presenter: (any ReceiverPresenter<Void, ServerState>)?

    /// Reference to the delegate, set by the coordinator on creation.
    weak var delegate: (any ServerDelegate)?

    /// State that holds the user's changes in the form. It is never presented; it's just our scratchpad.
    var state = ServerState()

    func receive(_ action: ServerAction) async {
        switch action {
        case .schemeChanged(let scheme):
            state.scheme = scheme
        case .textFieldChanged(let field, let text):
            let fieldPath: WritableKeyPath<ServerState, String> = switch field {
            case .host: \.host
            case .password: \.password
            case .port: \.port
            case .username: \.username
            }
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
                await delegate?.userEdited(serverInfo: serverInfo)
            } catch {
                coordinator?.showAlert(title: "Error", message: error.issue)
            }
        }
    }
}

/// Protocol that defines a delegate to whom we can report when the user taps the Done button.
@MainActor
protocol ServerDelegate: AnyObject {
    func userEdited(serverInfo: ServerInfo) async
}
