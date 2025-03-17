import Foundation

struct JukeboxResponse: InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let jukeboxStatus: JukeboxStatus?
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

struct JukeboxStatus: Codable, Equatable {
    let currentIndex: Int
    let playing: Bool
    let gain: Double
}
