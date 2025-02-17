import UIKit

class PingViewController: UIViewController, Presenter {
    var processor: (any Processor<PingAction, PingState>)?

    @IBOutlet var successLabel: UILabel!

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
        successLabel.isHidden = !state.success
    }
}

