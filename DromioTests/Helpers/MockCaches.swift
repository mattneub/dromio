@testable import Dromio

@MainActor
final class MockCaches: CachesType {
    var albumsList: [Dromio.SubsonicAlbum]?
    var allArtists: [Dromio.SubsonicArtist]?
    var artistsWhoAreArtists: [Dromio.SubsonicArtist]?
    var artistsWhoAreComposers: [Dromio.SubsonicArtist]?
    var methodsCalled = [String]()

    func fetch<T>(_ key: ReferenceWritableKeyPath<Dromio.Caches, Optional<T>>, using: () async throws -> T) async throws -> T where T : Sendable {
        fatalError("unsupported")
    }

    func clear() {
        methodsCalled.append(#function)
    }

}
