@testable import Dromio
import Testing

@MainActor
struct PersistenceTests {
    let subject = Persistence()
    let defaults = MockUserDefaults()
    let keychain = MockKeychain()

    init() {
        Persistence.defaults = defaults
        Persistence.keychain = keychain
    }

    @Test("saveCurrentPlaylist: encodes songs as strings, saves array to defaults")
    func saveCurrentPlaylist() throws {
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 100,
            contributors: nil
        )
        try subject.saveCurrentPlaylist(songList: [song])
        #expect(defaults.key == "currentPlaylist")
        let expected = """
        {
          "album" : "Album",
          "albumId" : "2",
          "artist" : "Artist",
          "displayComposer" : "Me",
          "duration" : 100,
          "id" : "1",
          "title" : "Title",
          "track" : 1,
          "year" : 1970
        }
        """
        let result = try #require(defaults.value as? [String])
        #expect(result == [expected])
    }

    @Test("loadCurrentPlaylist: decodes songs as strings to array of song")
    func loadCurrentPlaylist() throws {
        let song = """
        {
          "album" : "Album",
          "albumId" : "2",
          "artist" : "Artist",
          "displayComposer" : "Me",
          "duration" : 100,
          "id" : "1",
          "title" : "Title",
          "track" : 1,
          "year" : 1970
        }
        """
        defaults.stringArrayToReturn = [song]
        let expected = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 100,
            contributors: nil,
            downloaded: false
        )
        let result = try subject.loadCurrentPlaylist()
        #expect(defaults.key == "currentPlaylist")
        #expect(result == [expected])
    }

    @Test("save(servers:) strips out the password and saves to defaults; saves password to keychain keyed by host+username")
    func saveServers() throws {
        let server = ServerInfo(
            scheme: "scheme",
            host: "host",
            port: 1,
            username: "username",
            password: "password",
            version: "version"
        )
        try subject.save(servers: [server])
        #expect(defaults.key == "servers")
        let expected = """
        {
          "host" : "host",
          "password" : "",
          "port" : 1,
          "scheme" : "scheme",
          "username" : "username",
          "version" : "version"
        }
        """
        let result = try #require(defaults.value as? [String])
        #expect(result == [expected])
        let password = try #require(keychain.dictionary["username@host"])
        #expect(password == "password")
    }

    @Test("load(servers:) returns servers from defaults using password from keychain keyed by host+username")
    func loadServers() throws {
        let server = """
        {
          "host" : "host",
          "password" : "",
          "port" : 1,
          "scheme" : "scheme",
          "username" : "username",
          "version" : "version"
        }
        """
        defaults.stringArrayToReturn = [server]
        keychain.dictionary["username@host"] = "password"
        let result = try subject.loadServers()
        #expect(result.count == 1)
        let expected = ServerInfo(
            scheme: "scheme",
            host: "host",
            port: 1,
            username: "username",
            password: "password",
            version: "version"
        )
        #expect(result[0] == expected)
    }
}
