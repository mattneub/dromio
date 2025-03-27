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

    @Test("setList: sets the list")
    func setListSetsList() {
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
        subject.list = []
        subject.setList([song1])
        #expect(subject.list == [song1])
    }

    @Test("append: appends to the list, throws if id already in list")
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
        let song3 = SubsonicSong(
            id: "1", // id is all that matters
            title: "Title3",
            album: "Album3",
            artist: "Artist3",
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
            try subject.append(song3)
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

    @Test("move: moves what you said to move")
    func move() {
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
        subject.move(from: 1, to: 0)
        #expect(subject.list == [song2, song1])
        subject.move(from: 0, to: 1)
        #expect(subject.list == [song1, song2])
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
