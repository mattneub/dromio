/// Processor containing logic for the Ping view controller.
///
@MainActor
final class PingProcessor: Processor {
    /// A reference to the root coordinator, set by the coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// A reference to our presenter (the Ping view controller), set by the coordinator on creation.
    weak var presenter: (any ReceiverPresenter<Void, PingState>)?

    /// The state. Mutating the state causes the presenter to present the state.
    var state = PingState() {
        didSet {
            presenter?.present(state)
        }
    }

    func receive(_ action: PingAction) async {
        switch action {
        case .doPing:
            do {
                if services.urlMaker.currentServerInfo == nil {
                    guard let server = try services.persistence.loadServers().first else {
                        coordinator?.showServer()
                        return
                    }
                    services.urlMaker.currentServerInfo = server
                }
                try await services.requestMaker.ping()
                state.success = .success
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.6))
                }
                coordinator?.showAlbums()
            } catch NetworkerError.message(let message) {
                state.success = .failure(message: message)
            } catch {
                state.success = .failure(message: error.localizedDescription)
            }
        case .reenterServerInfo:
            coordinator?.showServer()
        }
    }
}
