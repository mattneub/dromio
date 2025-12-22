@testable import Dromio
import Testing
import Foundation

struct ArrayTests {
    let album1 = SubsonicAlbum(id: "1", name: "The buck stops here", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album2 = SubsonicAlbum(id: "2", name: "Bust my britches", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album3 = SubsonicAlbum(id: "3", name: "Büild back better", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album4 = SubsonicAlbum(id: "4", name: "400 blows", sortName: nil, artist: nil, songCount: 0, song: nil)
    let album5 = SubsonicAlbum(id: "5", name: "50 ways", sortName: nil, artist: nil, songCount: 0, song: nil)
    let artist1 = SubsonicArtist(id: "1", name: "The buck stops here", albumCount: nil, album: nil, roles: nil, sortName: nil)
    let artist2 = SubsonicArtist(id: "2", name: "Bust my britches", albumCount: nil, album: nil, roles: nil, sortName: nil)
    let artist3 = SubsonicArtist(id: "3", name: "Büild back better", albumCount: nil, album: nil, roles: nil, sortName: nil)
    let artist4 = SubsonicArtist(id: "4", name: "[hey]", albumCount: nil, album: nil, roles: nil, sortName: nil)
    let artist5 = SubsonicArtist(id: "5", name: "[ha]", albumCount: nil, album: nil, roles: nil, sortName: nil)
    let song1 = SubsonicSong(id: "1", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
    let song2 = SubsonicSong(id: "2", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
    let song3 = SubsonicSong(id: "3", title: "title", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)

    @Test("sorted: sorts albums correctly")
    func sortedAlbums() {
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

    @Test("sorted: sorts artists correctly")
    func sortedArtists() {
        let data = [artist1, artist2, artist3, artist4, artist5]
        let sorted = data.sorted
        let result = sorted.map { $0.id }
        #expect(result == [
            "5", // ha before hey, both come first
            "4",
            "1", // "The" is stripped off
            "3", // umlaut is disregarded, sorts with ordinary "u"
            "2",
        ])
    }

    @Test("buildSequence: gives array from first match to end; if no match, returns empty array")
    func buildSequence() {
        var list = [song1, song2, song3]
        var result = list.buildSequence(startingWith: song2)
        #expect(result == [song2, song3])
        list = [song2, song3]
        result = list.buildSequence(startingWith: song1)
        #expect(result == [])
    }
}
