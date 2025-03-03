import UIKit

/// View controller for when we ping the server.
class PingViewController: UIViewController, Presenter {
    /// A reference to the PingProcessor, set by the coordinator on creation.
    var processor: (any Processor<PingAction, PingState>)?

    /// Label to be displayed when the ping succeeds.
    @IBOutlet var successLabel: UILabel!

    /// Label to be displayed when the ping fails.
    @IBOutlet var failureLabel: UILabel!

    /// Button that lets the user ask to summon the Server view again.
    @IBOutlet var reenterButton: UIButton!

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
            reenterButton.isHidden = true
        case .failure(let message):
            successLabel.isHidden = true
            failureLabel.text = message
            failureLabel.isHidden = false
            reenterButton.isHidden = false
        }
    }

    @IBAction func doReenterButton (_ sender: UIButton) {
        Task {
            await processor?.receive(.reenterServerInfo)
        }
    }

}

