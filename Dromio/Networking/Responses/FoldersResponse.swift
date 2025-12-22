import Foundation

/// Inner response for the `getFolders` request.
struct FoldersResponse: @MainActor InnerResponse {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let musicFolders: FoldersResult
    let error: SubsonicError? // may not be possible, but present for parity with ping
}

/// Type of the `musicFolders` property of the FoldersResponse.
struct FoldersResult: Codable {
    let musicFolder: [SubsonicFolder]
}
