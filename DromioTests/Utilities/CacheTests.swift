@testable import Dromio
import Testing

struct CacheTests {
    @Test("Cache memoizes as expected")
    func cache() async throws {
        let subject = Cache()
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

    @Test("clear: clears the cache")
    func cacheClear() {
        let subject = Cache()
        subject.allAlbums = [.init(id: "1", name: "Name", artist: nil, songCount: 0, song: nil)]
        subject.allArtists = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.artistsWhoAreArtists = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.artistsWhoAreComposers = [.init(id: "1", name: "Name", albumCount: nil, album: nil, roles: nil, sortName: nil)]
        subject.clear()
        #expect(subject.allAlbums == nil)
        #expect(subject.allArtists == nil)
        #expect(subject.artistsWhoAreArtists == nil)
        #expect(subject.artistsWhoAreComposers == nil)
    }
}
