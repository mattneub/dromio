import Foundation

/// Type of the array element of the FoldersResult.
/// Serves as data for the actual app
struct SubsonicFolder: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}
