import Foundation

/// Class that memoizes our biggest and most commonly used server fetch results.
@MainActor
final class Caches {
    /// For the result of `getAlbumList`
    var albumsList: [SubsonicAlbum]?

    /// For the result of `getArtistsBySearch`
    var allArtists: [SubsonicArtist]?

    /// For the artist-filtered version of `allArtists`
    var artistsWhoAreArtists: [SubsonicArtist]?

    /// For the composer-filtered version of `allArtists`
    var artistsWhoAreComposers: [SubsonicArtist]?

    /// The heart of the cache, implementing memoization. You give me the keypath of one of my properties and a
    /// function that returns its type. If I already have that property value, I just return it; if not,
    /// I perform your function, set my property to the result, and return the result.
    /// - Parameters:
    ///   - key: Keypath within Caches.
    ///   - using: Method to call to get the value if we don't already have it.
    /// - Returns: The value requested, either from our property or from calling the given method.
    ///
    func fetch<T: Sendable>(
        _ key: ReferenceWritableKeyPath<Caches, Optional<T>>,
        using: () async throws -> T
    ) async throws -> T {
        if let value = self[keyPath: key] {
            return value
        } else {
            let result = try await using()
            self[keyPath: key] = result
            return result
        }
    }
}
