@testable import Dromio
import Testing

@MainActor
struct PersistenceTests {
    let subject = Persistence()
    let defaults = MockUserDefaults()

    init() {
        Persistence.defaults = defaults
    }

    @Test("saveSongList: encodes songs as strings, saves array to defaults")
    func saveSongList() throws {
        let song = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: nil, suffix: nil, duration: 100)
        try subject.save(songList: [song], key: .currentPlaylist)
        #expect(defaults.key == "currentPlaylist")
        let expected = """
        {
          "artist" : "Artist",
          "duration" : 100,
          "id" : "1",
          "title" : "Title",
          "track" : 1
        }
        """
        let result = try #require(defaults.value as? [String])
        #expect(result == [expected])
    }

    @Test("loadSongList: decodes songs as strings to array of song")
    func loadLongList() throws {
        let song = """
        {
          "artist" : "Artist",
          "duration" : 100,
          "id" : "1",
          "title" : "Title",
          "track" : 1
        }
        """
        defaults.stringArrayToReturn = [song]
        let expected = SubsonicSong(id: "1", title: "Title", artist: "Artist", track: 1, albumId: nil, suffix: nil, duration: 100)
        let result = try subject.loadSongList(key: .currentPlaylist)
        #expect(defaults.key == "currentPlaylist")
        #expect(result == [expected])
    }
}
