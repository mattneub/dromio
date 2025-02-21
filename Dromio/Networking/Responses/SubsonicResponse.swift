import Foundation

/// Basic response to a request.
struct SubsonicResponse<T: InnerResponse>: Codable {
    let subsonicResponse: T
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

/// Protocol encompassing the commonality of goes into the `subsonicResponse` property of a
/// SubsonicResponse.
protocol InnerResponse: Codable {
    var status: String {get} // "ok" or "failed"
    var version: String {get}
    var type: String {get} // better be "navidrome" or we're outta here
    var serverVersion: String {get} // better start with "0.54.4" or higher, but we are not checking yet
    var openSubsonic: Bool {get} // should be true but we are not checking that either
    var error: SubsonicError? {get} // if `status` was "failed"
}

/// Type of the optional `error` property of the inner response.
struct SubsonicError: Codable {
    let code: Int
    let message: String
}

