import Foundation

struct ServerInfo {
    let scheme: String
    let host: String
    let port: Int
    let username: String // "u"
    let password: String // used to calculate "t" and "s"
    let version: String // "v"
}
