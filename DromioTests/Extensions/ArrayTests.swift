@testable import Dromio
import Testing
import Foundation

@MainActor
struct ArrayTests {
    let album1 = SubsonicAlbum(id: "1", name: "The buck stops here", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album2 = SubsonicAlbum(id: "2", name: "Bust my britches", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album3 = SubsonicAlbum(id: "3", name: "Büild back better", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album4 = SubsonicAlbum(id: "4", name: "400 blows", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album5 = SubsonicAlbum(id: "5", name: "50 ways", sortName: nil, artist: nil, songCount: 0, song: nil)

    @Test("sorted: sorts albums correctly")
    func sorted() {
        let data = [album1, album2, album3, album4, album5]
        let sorted = data.sorted
        let result = sorted.map { $0.id }
        #expect(result == [
            "5", // 50 is a smaller number than 400
            "4",
            "1", // "The" is stripped off
            "3", // umlaut is disregarded, sorts with ordinary "u"
            "2",
        ])
    }
}
