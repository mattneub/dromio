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
}
