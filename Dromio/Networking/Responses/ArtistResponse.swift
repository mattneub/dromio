import Foundation

/// Inner response for the `getArtist` request.
struct ArtistResponse: @MainActor InnerResponse { // for getArtist
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let artist: SubsonicArtist
    let error: SubsonicError? // may not be possible, but present for parity with ping
}
