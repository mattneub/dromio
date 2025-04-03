import UIKit

final class ServerViewController: UIViewController, AsyncReceiverPresenter {

    weak var processor: (any Receiver<ServerAction>)?

    @IBOutlet var scheme: UISegmentedControl!
    @IBOutlet var host: UITextField!
    @IBOutlet var port: UITextField!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let controller = presentationController {
            controller.delegate = self
        }
    }

    /// We don't actually need to be presented with any state.
    func present(_ state: ServerState) async {}

    /// Action of all the text fields.
    @IBAction func textFieldChanged (_ sender: UITextField) {
        let field: ServerAction.Field = switch sender {
        case host: .host
        case port: .port
        case username: .username
        case password: .password
        default: fatalError("impossible")
        }
        Task {
            await processor?.receive(.textFieldChanged(field, sender.text ?? ""))
        }
    }

    /// Action of the segmented control.
    @IBAction func segmentedControlChanged (_ sender: UISegmentedControl) {
        let scheme: ServerAction.Scheme = switch sender.selectedSegmentIndex {
        case 0: .http
        case 1: .https
        default: fatalError("impossible")
        }
        Task {
            await processor?.receive(.schemeChanged(scheme))
        }
    }

    /// Action of the Done button.
    @IBAction func doDone (_ sender: Any) {
        view.endEditing(true)
        Task {
            await processor?.receive(.done)
        }
    }
}

extension ServerViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        let servers = (try? services.persistence.loadServers()) ?? []
        return servers.count > 0 // i.e., if user has no servers, user cannot cancel
    }
}
