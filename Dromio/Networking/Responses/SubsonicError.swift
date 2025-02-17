import Foundation

struct SubsonicError: Decodable {
    let code: Int
    let message: String
}
