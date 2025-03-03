import UIKit

final class ServerViewController: UIViewController, ReceiverPresenter {

    weak var processor: (any Receiver<ServerAction>)?

    @IBOutlet var scheme: UISegmentedControl!
    @IBOutlet var host: UITextField!
    @IBOutlet var port: UITextField!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!

    /// We don't actually need to be presented with any state.
    func present(_ state: ServerState) {}

    func receive(_ effect: ServerEffect) async {
        switch effect {
        case .alertWithMessage(let message):
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

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
        Task {
            await processor?.receive(.done)
        }
    }

}
