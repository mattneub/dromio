@testable import Dromio
import Testing

@MainActor struct CachesTests {
    @Test("Caches memoizes as expected")
    func caches() async throws {
        let subject = Caches()
        #expect(subject.allArtists == nil)
        let artist = SubsonicArtist(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)
        let result = try await subject.fetch(\.allArtists) {
            [artist]
        }
        #expect(result == [artist])
        #expect(subject.allArtists == [artist])
        let result2 = try await subject.fetch(\.allArtists) {
            [SubsonicArtist(id: "2", name: "Name2", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        }
        #expect(result2 == result)
    }

    @Test("clear: clears the caches")
    func cachesClear() {
        let subject = Caches()
        subject.albumsList = [.init(id: "1", name: "Name", artist: nil, songCount: 0, song: nil)]
        subject.allArtists = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.artistsWhoAreArtists = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.artistsWhoAreComposers = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.clear()
        #expect(subject.albumsList == nil)
        #expect(subject.allArtists == nil)
        #expect(subject.artistsWhoAreArtists == nil)
        #expect(subject.artistsWhoAreComposers == nil)
    }
}
