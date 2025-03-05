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
            duration: nil
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
            duration: nil
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
            duration: nil
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
            duration: nil
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

    @Test("buildSequence: returns sequence from the given song onward")
    func buildSequence() {
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
            duration: nil
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
            duration: nil
        )
        subject.list = [song1, song2]
        var result = subject.buildSequence(startingWith: song1)
        #expect(result == [song1, song2])
        result = subject.buildSequence(startingWith: song2)
        #expect(result == [song2])
    }

    @Test("buildSequence: returns an empty sequence if the given song is not in the list")
    func buildSequenceNotInList() {
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
            duration: nil
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
            duration: nil
        )
        subject.list = [song1]
        let result = subject.buildSequence(startingWith: song2)
        #expect(result.isEmpty)
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
            duration: nil
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
            duration: nil
        )
        subject.list = [song1, song2]
        subject.clear()
        #expect(subject.list.isEmpty)
    }
}
