import Foundation

/// Protocol defining the public face of our RequestMaker.
@MainActor
protocol RequestMakerType: Sendable {
    func ping() async throws
    func getAlbumList() async throws -> [SubsonicAlbum]
    func getAlbumsRandom() async throws -> [SubsonicAlbum]
    // func getArtists() async throws -> [SubsonicArtist] // probably won't be using this
    func getArtistsBySearch() async throws -> [SubsonicArtist]
    func getSongsBySearch(query: String) async throws -> [SubsonicSong]
    func getAlbumsFor(artistId: String) async throws -> [SubsonicAlbum]
    func getSongsFor(albumId: String) async throws -> [SubsonicSong]
    func download(songId: String) async throws -> URL
    func stream(songId: String) async throws -> URL
}

/// Class that makes constructs and sends requests to the server. If you want to talk to the server,
/// this is the class you turn to. Other types such as URLMaker, Networker, and ResponseValidator are separated
/// from and subservient to this class, and are expressed as separate services, partly for clarity
/// of factoring and partly because it makes everything so much more testable.
///
@MainActor
final class RequestMaker: RequestMakerType {

    /// Utility method for looping through paginated network calls that fetch an array of some entity T, such
    /// as fetching all albums or all artists. We need this because Subsonic puts a maximum on how many
    /// of these entities we can ask for at a time.
    /// - Parameters:
    ///   - chunk: The size of the chunk to ask for each time through the loop. Typically this is 500,
    ///     the maximum permitted by the server.
    ///   - call: A function that takes two integers, representing the _chunk size_ and the _offset_ for
    ///     each request. The chunk size stays the same each time; the offset increments. For example, we
    ///     would first ask for 500 albums at offset 0, then 500 albums at offset 500, and so on until we
    ///     get back an answer with fewer than 500 albums, signifying the end.
    /// - Returns: The assembled array of all the entities. It may be too many entities for the server
    ///   to pass across the network in one go, but it is not too big for us to pass around within the app!
    func paginate<T: Sendable>(chunk: Int, _ call: (Int, Int) async throws -> [T]) async throws -> [T] {
        var offset = 0
        var array = [T]()
        var received = 0
        repeat {
            let result = try await call(chunk, offset)
            array.append(contentsOf: result)
            offset += chunk
            received = result.count
        } while received == chunk
        return array
    }

    /// "Ping" the server. This is more elaborate than a mere network ping; it is the most basic
    /// meaningful handshake, proving that the server is where we think it is, that it is a
    /// Navidrome server, that we have the username and password right, etc. Throws if anything
    /// goes wrong, providing a descriptive message of what the problem was, generated by us, by
    /// the server, or by the JSON decoder (_that_ message is, in fact, not very helpful). We always
    /// ping the server at launch (or as soon as we have server info), and we could in theory ping
    /// at any time just to make sure we still have a network connection to the server.
    ///
    func ping() async throws {
        let url = try services.urlMaker.urlFor(action: "ping")
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<PingResponse>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
    }

    /// Get a list of all albums in alphabetical title order and return it, throwing if anything goes wrong.
    /// - Returns: Array of all albums.
    ///
    func getAlbumList() async throws -> [SubsonicAlbum] {
        try await paginate(chunk: 500) { chunk, offset in
            return try await getAlbumList(chunk: chunk, offset: offset)
        }
    }

    /// Paginated subroutine of `getAlbumList`: get one chunk of albums starting at the given offset.
    /// - Parameters:
    ///   - chunk: Chunk size to ask for from the server.
    ///   - offset: Offset at which to tell the server to start.
    /// - Returns: Array of `chunk`-or-fewer albums. If fewer, that's the sign to stop fetching.
    ///
    func getAlbumList(chunk: Int, offset: Int) async throws -> [SubsonicAlbum] {
        let url = try services.urlMaker.urlFor(
            action: "getAlbumList2",
            additional: [
                "type": "alphabeticalByName",
                "size": String(chunk),
                "offset": String(offset),
            ]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<AlbumList2Response>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.albumList2.album
    }
    
    /// Get a list of 20 random albums.
    /// - Returns: The list of albums.
    func getAlbumsRandom() async throws -> [SubsonicAlbum] {
        let url = try services.urlMaker.urlFor(
            action: "getAlbumList2",
            additional: [
                "type": "random",
                "size": "20",
            ]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<AlbumList2Response>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.albumList2.album
    }
    
    /// Get a list of all artists.
    /// - Returns: The list of artists.
    ///
    /// We are not currently using this. The reason is that its idea of an "artist" is defined at
    /// the level of the album.
    ///
    func getArtists() async throws -> [SubsonicArtist] {
        let url = try services.urlMaker.urlFor(
            action: "getArtists"
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<ArtistsResponse>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        let indexList = jsonResponse.subsonicResponse.artists.index
        let arrayOfArrayOfArtist = indexList.map { $0.artist }
        let arrayOfArtist = arrayOfArrayOfArtist.flatMap { $0 }
        return arrayOfArtist
    }
    
    /// Get a list of all artists, meaning _really_ a list of _all_ artists in the full sense that
    /// Navidrome understands it, i.e. having the "artist" or "composer" role.
    /// - Returns: The list of artists.
    ///
    /// To obtain this list, we have to resort to a `search3` that asks for all artists.
    /// This will include composers, so filtering to those whose `roles` include `"artists"`
    /// or those whose `roles` include `"composer"` is up to the caller.
    ///
    func getArtistsBySearch() async throws -> [SubsonicArtist] {
        try await paginate(chunk: 500) { chunk, offset in
            return try await getArtistsBySearch(chunk: chunk, offset: offset)
        }
    }

    /// Pagination helper of the preceding.
    func getArtistsBySearch(chunk: Int, offset: Int) async throws -> [SubsonicArtist] {
        let url = try services.urlMaker.urlFor(
            action: "search3",
            additional: [
                "query": "",
                "songCount": "0",
                "albumCount": "0",
                "artistCount": String(chunk),
                "artistOffset": String(offset),
            ]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<SearchResult3Response>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.searchResult3.artist ?? []
    }

    /// Get the list of all songs.
    func getSongsBySearch(query: String) async throws -> [SubsonicSong] {
        try await paginate(chunk: 500) { chunk, offset in
            return try await getSongsBySearch(query: query, chunk: chunk, offset: offset)
        }
    }

    /// Pagination helper of the preceding.
    func getSongsBySearch(query: String, chunk: Int, offset: Int) async throws -> [SubsonicSong] {
        let url = try services.urlMaker.urlFor(
            action: "search3",
            additional: [
                "query": query,
                "albumCount": "0",
                "artistCount": "0",
                "songCount": String(chunk),
                "songOffset": String(offset),
            ]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<SearchResult3Response>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.searchResult3.song ?? []
    }

    /// Given an artist id, fetch that artist's participatory albums. This
    /// works in coordination with the `"artist"` role only if Navidrome's Subsonic.ArtistParticipations
    /// is turned on.
    /// - Parameter artistId: The artist id.
    /// - Returns: The list of albums.
    func getAlbumsFor(artistId: String) async throws -> [SubsonicAlbum] {
        let url = try services.urlMaker.urlFor(
            action: "getArtist",
            additional: [
                "id": artistId,
            ]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<ArtistResponse>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.artist.album ?? []
    }

    /// Get an album along with its songs, and return the songs, throwing if anything goes wrong.
    /// - Parameter albumId: The id of the album.
    /// - Returns: An array of the songs of the specified albums.
    func getSongsFor(albumId: String) async throws -> [SubsonicSong] {
        let url = try services.urlMaker.urlFor(
            action: "getAlbum",
            additional: ["id": albumId]
        )
        let data = try await services.networker.performRequest(url: url)
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<AlbumResponse>.self, from: data)
        try await services.responseValidator.validateResponse(jsonResponse)
        return jsonResponse.subsonicResponse.album.song ?? []
    }
    
    /// Download a song, throwing if anything goes wrong.
    /// - Parameter songId: The id of the desired song.
    /// - Returns: The file URL where the song data resides locally after downloading.
    func download(songId: String) async throws -> URL {
        let url = try services.urlMaker.urlFor(
            action: "download",
            additional: ["id": songId]
        )
        return try await services.networker.performDownloadRequest(url: url)
    }

    /// Stream a song, throwing if anything goes wrong.
    /// - Parameter songId: The id of the desired song.
    /// - Returns: The request URL itself.
    func stream(songId: String) async throws -> URL {
        let url = try services.urlMaker.urlFor(
            action: "stream",
            additional: ["id": songId]
        )
        return url
    }

}
