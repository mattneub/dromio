import Foundation

/// Processor containing the logic for the server view controller.
@MainActor
final class ServerProcessor: AsyncProcessor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any AsyncReceiverPresenter<Void, ServerState>)?

    weak var delegate: (any ServerDelegate)?

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

@MainActor
protocol ServerDelegate: AnyObject {
    func userEdited(serverInfo: ServerInfo) async
}
