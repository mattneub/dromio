import Foundation

/// Inner response for the `getUser` request.
struct UserResponse: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let user: SubsonicUser
    let error: SubsonicError? // may not be possible, but present for parity with ping
}
