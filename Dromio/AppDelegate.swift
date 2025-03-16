import UIKit
import os.log

/// The sole global instance of the services.
@MainActor
var services: Services = Services()

/// The sole global instance of the caches.
@MainActor
var caches: Caches = Caches()

/// Global info about the user's jukebox role.
@MainActor
var userHasJukeboxRole = false {
    didSet {
        print("jukebox?", userHasJukeboxRole)
    }
}

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

