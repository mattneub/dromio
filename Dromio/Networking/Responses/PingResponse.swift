import Foundation

struct PingResponse: InnerResponse {
    let status: String // "ok" or "failed"
    let version: String
    let type: String // better be "navidrome" or we're outta here
    let serverVersion: String // better start with "0.54.4" or higher
    let openSubsonic: Bool
    let error: SubsonicError? // if `status` was "failed"
}
