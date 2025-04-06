@testable import Dromio

@MainActor
final class MockCache: CacheType {
    var allAlbums: [SubsonicAlbum]?
    var allArtists: [SubsonicArtist]?
    var artistsWhoAreArtists: [SubsonicArtist]?
    var artistsWhoAreComposers: [SubsonicArtist]?
    var methodsCalled = [String]()

    func fetch<T>(_ key: ReferenceWritableKeyPath<Cache, Optional<T>>, using: () async throws -> T) async throws -> T where T : Sendable {
        fatalError("unsupported")
    }

    func clear() {
        methodsCalled.append(#function)
    }

}
