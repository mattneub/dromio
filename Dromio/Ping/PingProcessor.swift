/// Processor containing logic for the Ping view controller.
///
@MainActor
final class PingProcessor: Processor {
    var presenter: (any Presenter<PingState>)?

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
                try await services.networker.ping()
                state.success = .success
            } catch NetworkerError.message(let message) {
                state.success = .failure(message: message)
            } catch {
                state.success = .failure(message: error.localizedDescription)
            }
        }
    }
}
