@testable import Dromio
import Testing

@MainActor
struct PlaylistTests {
    @Test("append: appends to the list, throws if already in list")
    func append() throws {
        let subject = Playlist()
        let song1 = SubsonicSong(id: "1", title: "Title1", artist: "Artist1", track: 1, albumId: "2", suffix: nil, duration: nil)
        let song2 = SubsonicSong(id: "2", title: "Title2", artist: "Artist2", track: 2, albumId: "2", suffix: nil, duration: nil)
        try subject.append(song1)
        #expect(subject.list == [song1])
        try subject.append(song2)
        #expect(subject.list == [song1, song2])
        #expect {
            try subject.append(song1)
        } throws: { error in
            error is PlaylistError
        }
    }
}
