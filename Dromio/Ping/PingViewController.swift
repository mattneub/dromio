import UIKit

class PingViewController: UIViewController, Presenter {
    var processor: (any Processor<PingAction, PingState>)?

    @IBOutlet var successLabel: UILabel!
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

