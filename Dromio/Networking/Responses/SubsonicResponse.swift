import Foundation

struct SubsonicResponse<T: InnerResponse>: Codable {
    let subsonicResponse: T
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

protocol InnerResponse: Codable {
    var status: String {get}
    var version: String {get}
    var type: String {get}
    var serverVersion: String {get}
    var openSubsonic: Bool {get}
    var error: SubsonicError? {get}
}
