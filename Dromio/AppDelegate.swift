import UIKit
import os.log

/// The sole global instance of the services.
@MainActor
var services: Services = Services.shared

/// Global info about the user's jukebox role.
@MainActor
var userHasJukeboxRole = false

/// Globally available Logger instance.
@MainActor
let logger = Logger(subsystem: "dromio", category: "debugging")

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

}

