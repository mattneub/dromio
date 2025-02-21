import UIKit

/// View controller for when we ping the server.
class PingViewController: UIViewController, Presenter {
    /// A reference to the PingProcessor, set by the coordinator on creation.
    var processor: (any Processor<PingAction, PingState>)?

    /// Label to be displayed when the ping succeeds.
    @IBOutlet var successLabel: UILabel!

    /// Label to be displayed when the ping fails.
    @IBOutlet var failureLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ping"
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            await processor?.receive(.doPing)
        }
    }

    func present(_ state: PingState) {
        switch state.success {
        case .success:
            successLabel.isHidden = false
            failureLabel.isHidden = true
        case .failure(let message):
            successLabel.isHidden = true
            failureLabel.text = message
            failureLabel.isHidden = false
        }
    }
}

