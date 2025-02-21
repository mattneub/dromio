/// Processor containing logic for the Ping view controller.
///
@MainActor
final class PingProcessor: Processor {
    /// A reference to the root coordinator, set by the coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// A reference to our presenter (the Ping view controller), set by the coordinator on creation.
    weak var presenter: (any Presenter<PingState>)?

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
                try await services.requestMaker.ping()
                state.success = .success
                coordinator?.showAlbums()
            } catch NetworkerError.message(let message) {
                state.success = .failure(message: message)
            } catch {
                state.success = .failure(message: error.localizedDescription)
            }
        }
    }
}
