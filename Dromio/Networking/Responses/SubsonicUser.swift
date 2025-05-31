import Foundation

/// Type of the UserResponse `user` property.
struct SubsonicUser: Codable, Equatable {
    let adminRole: Bool
    let scrobblingEnabled: Bool
    let downloadRole: Bool
    let streamRole: Bool
    let jukeboxRole: Bool
}
