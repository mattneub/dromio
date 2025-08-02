import UIKit
import os.log

/// The sole global instance of the services.
@MainActor
var services: Services = Services.shared

/// Global info about the user's jukebox role.
@MainActor
var userHasJukeboxRole = false

/// Global info about available music folders: which ones exist and which (if any) is current.
@MainActor
var folders = [SubsonicFolder]()
//@MainActor
//var currentFolder: Int?

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

