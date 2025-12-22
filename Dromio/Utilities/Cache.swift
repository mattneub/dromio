import Foundation

/// Protocol describing our Cache class, so we can mock it for testing.
protocol CacheType {
    var allAlbums: [SubsonicAlbum]? { get set }
    var allArtists: [SubsonicArtist]? { get set }
    var artistsWhoAreArtists: [SubsonicArtist]? { get set }
    var artistsWhoAreComposers: [SubsonicArtist]? { get set }
    func fetch<T: Sendable>(
        _ key: ReferenceWritableKeyPath<Cache, Optional<T>>,
        using: () async throws -> T
    ) async throws -> T
    func clear()
}

/// Class that memoizes our biggest and most commonly used server fetch results.
final class Cache: CacheType {
    /// For the result of `getAlbumList`
    var allAlbums: [SubsonicAlbum]?

    /// For the result of `getArtistsBySearch`
    var allArtists: [SubsonicArtist]?

    /// For the artist-filtered version of `allArtists`
    var artistsWhoAreArtists: [SubsonicArtist]?

    /// For the composer-filtered version of `allArtists`
    var artistsWhoAreComposers: [SubsonicArtist]?

    /// The heart of the cache, implementing memoization.
    /// - Parameters:
    ///   - key: Keypath within Cache.
    ///   - using: Method to call to obtain the value if we don't already have it.
    /// - Returns: The value requested, either from our property or from calling the given method.
    ///
    /// The principle here is very simple. You give me the keypath of one of my properties and a
    /// function that returns its type. Then:
    ///   * If I already have that property value, I just return it.
    ///   * If not, I perform your function, set my property to the result, and return the result.
    ///
    func fetch<T: Sendable>(
        _ key: ReferenceWritableKeyPath<Cache, Optional<T>>,
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

    /// Clear the cache by nilifying and thus erasing any data we've been maintaining.
    func clear() {
        allAlbums = nil
        allArtists = nil
        artistsWhoAreArtists = nil
        artistsWhoAreComposers = nil
    }
}
