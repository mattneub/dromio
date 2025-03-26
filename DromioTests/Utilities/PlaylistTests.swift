@testable import Dromio
import Testing

@MainActor
struct PlaylistTests {
    let subject = Playlist()
    let persistence = MockPersistence()

    init() {
        services.persistence = persistence
    }

    @Test("modifying list saves to defaults")
    func setList() {
        let song1 = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.list = [song1]
        #expect(persistence.songList == [song1])
        #expect(persistence.key == .currentPlaylist)
    }

    @Test("retrieving list retrieves from defaults")
    func getList() {
        let song1 = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        persistence.songList = [song1]
        #expect(subject.list == [song1])
        #expect(persistence.key == .currentPlaylist)
    }

    @Test("append: appends to the list, throws if already in list")
    func append() throws {
        let song1 = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
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

    @Test("delete: removes the given song from the list")
    func delete() {
        let song1 = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.list = [song1, song2]
        subject.delete(song: song2)
        #expect(subject.list == [song1])
    }

    @Test("clear: empties the list")
    func clear() {
        let song1 = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        let song2 = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: nil,
            contributors: nil
        )
        subject.list = [song1, song2]
        subject.clear()
        #expect(subject.list.isEmpty)
    }
}
