import Foundation

/// Inner response for the `ping` request. Contains enough info to tell whether you're talking
/// correctly to the server.
struct PingResponse: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let error: SubsonicError?
}
