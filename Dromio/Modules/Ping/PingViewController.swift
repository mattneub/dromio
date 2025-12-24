import UIKit

/// View controller for when we ping the server.
class PingViewController: UIViewController, ReceiverPresenter {
    /// A reference to the PingProcessor, set by the coordinator on creation.
    weak var processor: (any Processor<PingAction, PingState, Void>)?

    /// Label shown as we are trying to ping and after we know the result.
    @IBOutlet var pingingLabel: UILabel!

    /// Label to be displayed when the ping succeeds.
    @IBOutlet var successLabel: UILabel!

    /// Label to be displayed when the ping fails.
    @IBOutlet var failureLabel: UILabel!

    /// Button that lets the user ask to summon the Server Info view again.
    @IBOutlet var reenterButton: UIButton!

    /// Button that lets the user pick a server.
    @IBOutlet var pickServerButton: UIButton!

    /// Button that lets the user pick a music folder.
    @IBOutlet var pickFolderButton: UIButton!

    /// Button that lets the user delete a server.
    @IBOutlet var deleteServerButton: UIButton!

    /// Button that lets the user enter offline mode.
    @IBOutlet var offlineModeButton: UIButton!

    /// Flag so that we know whether we are appearing at launch or later in the app's lifetime.
    private var firstTime = true

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        Task {
            guard firstTime else {
                await processor?.receive(.choices)
                return
            }
            firstTime = false
            await processor?.receive(.launch)
        }
    }

    func present(_ state: PingState) async {
        pingingLabel.isHidden = true
        successLabel.isHidden = true
        failureLabel.isHidden = true
        failureLabel.text = "Failure!" // this is the only one that can change
        reenterButton.isHidden = true
        pickServerButton.isHidden = true
        deleteServerButton.isHidden = true
        pickFolderButton.isHidden = true
        offlineModeButton.isHidden = true
        switch state.status {
        case .empty: break
        case .unknown:
            pingingLabel.isHidden = false
        case .success:
            pingingLabel.isHidden = false
            successLabel.isHidden = false
        case .failure(let message):
            pingingLabel.isHidden = false
            failureLabel.text = message
            failureLabel.isHidden = false
            reenterButton.isHidden = false
            pickServerButton.isHidden = false
            deleteServerButton.isHidden = false
            pickFolderButton.isHidden = false
            offlineModeButton.isHidden = false
        case .choices:
            reenterButton.isHidden = false
            pickServerButton.isHidden = false
            deleteServerButton.isHidden = false
            pickFolderButton.isHidden = false
            offlineModeButton.isHidden = false
        }
        pickFolderButton.isEnabled = state.enablePickFolderButton && state.status == .choices
    }

    @IBAction func doReenterButton (_ sender: UIButton) {
        Task {
            await processor?.receive(.reenterServerInfo)
        }
    }

    @IBAction func doPickServerButton (_ sender: UIButton) {
        Task {
            await processor?.receive(.pickServer)
        }
    }

    @IBAction func doPickFolderButton(_ sender: UIButton) {
        Task {
            await processor?.receive(.pickFolder)
        }
    }

    @IBAction func doDeleteServerButton (_ sender: UIButton) {
        Task {
            await processor?.receive(.deleteServer)
        }
    }

    @IBAction func doOfflineModeButton (_ sender: UIButton) {
        Task {
            await processor?.receive(.offlineMode)
        }
    }


}

