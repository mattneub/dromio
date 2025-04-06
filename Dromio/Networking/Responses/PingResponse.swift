import Foundation

/// Inner response for the `ping` request.
struct PingResponse: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let error: SubsonicError?
}
