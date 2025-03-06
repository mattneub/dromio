@testable import Dromio
import Testing
import Foundation

@MainActor
struct RequestMakerTests {
    let subject = RequestMaker()
    let networker = MockNetworker()
    let responseValidator = MockResponseValidator()
    let urlMaker = MockURLMaker()

    init() {
        services.networker = networker
        services.responseValidator = responseValidator
        services.urlMaker = urlMaker
    }

    @Test("paginate: calls handler with incremented offset until fewer than chunk items are returned, returns accumulated result")
    func paginate() async throws {
        var count = 0
        let result = try await subject.paginate(chunk: 2) { chunk, offset -> [Int] in
            count += 1
            switch count {
            case 1:
                #expect(chunk == 2)
                #expect(offset == 0)
                return [1, 2]
            case 2:
                #expect(chunk == 2)
                #expect(offset == 2)
                return [3, 4]
            case 3:
                #expect(chunk == 2)
                #expect(offset == 4)
                return [5]
            default:
                #expect(Bool(false)) // should never get here!
                return []
            }
        }
        #expect(result == [1, 2, 3, 4, 5])
    }

    @Test("ping: calls url maker with action ping, calls networker, calls validator")
    func ping() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        try await subject.ping()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:)"])
        #expect(urlMaker.action == "ping")
        #expect(urlMaker.additional == nil)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
    }

    @Test("ping: rethrows urlMaker throw")
    func pingUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.ping()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("ping: rethrows networker throw")
    func pingNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.ping()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("ping: rethrows decode error")
    func pingDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.ping()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("ping: rethrows validator error")
    func pingValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.ping()
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getAlbumList: calls url maker with action getAlbumList2 add additional, calls networker, calls validator, returns list")
    func getAlbumList() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: AlbumList2Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                albumList2: AlbumsResponse(album: [SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getAlbumList()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:)"])
        #expect(urlMaker.action == "getAlbumList2")
        let expectedAdditional: KeyValuePairs = ["type": "alphabeticalByName", "size": "500", "offset": "0"]
        let additional = try #require(urlMaker.additional)
        #expect(expectedAdditional.map { $0.key } == additional.map { $0.key })
        #expect(expectedAdditional.map { $0.value } == additional.map { $0.value })
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(list == [SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)])
    }

    @Test("getAlbumList: paginates with chunk 500")
    func getAlbumListPaginate() async throws {
        let payload1 = SubsonicResponse(
            subsonicResponse: AlbumList2Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                albumList2: AlbumsResponse(album: Array(repeating: SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil), count: 500)),
                error: nil
            )
        )
        let payload2 = SubsonicResponse(
            subsonicResponse: AlbumList2Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                albumList2: AlbumsResponse(album: Array(repeating: SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil), count: 2)),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload1), try! JSONEncoder().encode(payload2)]
        let list = try await subject.getAlbumList()
        #expect(list.count == 502)
    }

    @Test("getAlbumList: rethrows urlMaker throw")
    func getAlbumListUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getAlbumList()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getAlbumList: rethrows networker throw")
    func getAlbumListNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getAlbumList()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getAlbumList: rethrows decode error")
    func getAlbumListDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getAlbumList()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getAlbumList: rethrows validator error")
    func getAlbumListValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: AlbumList2Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                albumList2: AlbumsResponse(album: [SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getAlbumList()
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getSongsFor: calls url maker with action getAlbum and additional id, calls networker, calls validator, returns list")
    func getSongFor() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: AlbumResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                album: SubsonicAlbum(
                    id: "1",
                    name: "title",
                    sortName: nil,
                    artist: "Artist",
                    songCount: 10,
                    song: [.init(
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
                    )]
                ),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getSongsFor(albumId: "1")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:)"])
        #expect(urlMaker.action == "getAlbum")
        let expectedAdditional: KeyValuePairs = ["id": "1"]
        let additional = try #require(urlMaker.additional)
        #expect(expectedAdditional.map { $0.key } == additional.map { $0.key })
        #expect(expectedAdditional.map { $0.value } == additional.map { $0.value })
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(
            list == [
                .init(
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
                ),
            ]
        )
    }

    @Test("getSongsFor: rethrows urlMaker throw")
    func getSongsForUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getSongsFor(albumId: "1")
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getSongsFor: rethrows networker throw")
    func getSongsForNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getSongsFor(albumId: "1")
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getSongsFor: rethrows decode error")
    func getSongsForDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getSongsFor(albumId: "1")
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getSongsFor: rethrows validator error")
    func getSongsForValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: AlbumResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                album: SubsonicAlbum(
                    id: "1",
                    name: "title",
                    sortName: nil,
                    artist: "Artist",
                    songCount: 10,
                    song: [.init(
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
                    )]
                ),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getSongsFor(albumId: "1")
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("download: calls url maker with action download and additional id, calls networker, returns url")
    func download() async throws {
        networker.urlToReturn = URL(string: "file://myfile")!
        let url = try await subject.download(songId: "1")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:)"])
        #expect(urlMaker.action == "download")
        let expectedAdditional: KeyValuePairs = ["id": "1"]
        let additional = try #require(urlMaker.additional)
        #expect(expectedAdditional.map { $0.key } == additional.map { $0.key })
        #expect(expectedAdditional.map { $0.value } == additional.map { $0.value })
        #expect(networker.methodsCalled == ["performDownloadRequest(url:)"])
        #expect(url == URL(string: "file://myfile")!)
    }

    @Test("download: rethrows urlMaker throw")
    func downloadUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.download(songId: "1")
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("download: rethrows networker throw")
    func downloadNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.download(songId: "1")
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("stream: calls url maker with action download and additional id, does not call networker, returns url")
    func stream() async throws {
        urlMaker.urlToReturn = URL(string: "http://example.com")!
        let url = try await subject.stream(songId: "1")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:)"])
        #expect(urlMaker.action == "stream")
        let expectedAdditional: KeyValuePairs = ["id": "1"]
        let additional = try #require(urlMaker.additional)
        #expect(expectedAdditional.map { $0.key } == additional.map { $0.key })
        #expect(expectedAdditional.map { $0.value } == additional.map { $0.value })
        #expect(networker.methodsCalled.isEmpty)
        #expect(url == URL(string: "http://example.com")!)
    }

    @Test("stream: rethrows urlMaker throw")
    func streamUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.stream(songId: "1")
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }
}
