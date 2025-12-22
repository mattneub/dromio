@testable import Dromio
import Testing
import Foundation

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
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "ping")
        #expect(urlMaker.additional == nil)
        #expect(urlMaker.folderRestrictable == false)
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

    @Test("getUser: calls url maker with action getUser, calls networker, calls validator")
    func getUser() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: UserResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                user: .init(adminRole: true, scrobblingEnabled: false, downloadRole: true, streamRole: true, jukeboxRole: false),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let user = try await subject.getUser()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getUser")
        #expect(urlMaker.additional == nil)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(user == .init(adminRole: true, scrobblingEnabled: false, downloadRole: true, streamRole: true, jukeboxRole: false))
    }

    @Test("getUser: rethrows urlMaker throw")
    func getUserUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getUser()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getUser: rethrows networker throw")
    func getUserNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getUser()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getUser: rethrows decode error")
    func getUserDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getUser()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getUser: rethrows validator error")
    func getUserValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: UserResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                user: .init(adminRole: true, scrobblingEnabled: false, downloadRole: true, streamRole: true, jukeboxRole: false),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getUser()
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getFolders: calls url maker with action getMusicFolders, calls networker, calls validator")
    func getFolders() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: FoldersResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                musicFolders: .init(musicFolder: [.init(id: 1, name: "Music Folder")]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let folders = try await subject.getFolders()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getMusicFolders")
        #expect(urlMaker.additional == nil)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(folders == [.init(id: 1, name: "Music Folder")])
    }

    @Test("getFolders: rethrows urlMaker throw")
    func getFoldersUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getFolders()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getFolders: rethrows networker throw")
    func getFoldersNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getFolders()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getFolders: rethrows decode error")
    func getFoldersDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getFolders()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getFolders: rethrows validator error")
    func getFoldersValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: FoldersResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                musicFolders: .init(musicFolder: [.init(id: 1, name: "Music Folder")]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getFolders()
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getAlbumList: calls url maker with action getAlbumList2 and additional, calls networker, calls validator, returns list")
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
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getAlbumList2")
        let expectedAdditional: [URLQueryItem] = [
            .init(name: "type", value: "alphabeticalByName"),
            .init(name: "size", value: "500"),
            .init(name: "offset", value: "0"),
        ]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == true)
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
                albumList2: AlbumsResponse(album: Array(repeating: SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil),
                                                        count: 500)),
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
                albumList2: AlbumsResponse(album: Array(repeating: SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil),
                                                        count: 2)),
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

    @Test("getAlbumsRandom: calls url maker with action getAlbumList2 and additional, calls networker, calls validator, returns list")
    func getAlbumsRandom() async throws {
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
        let list = try await subject.getAlbumsRandom()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getAlbumList2")
        let expectedAdditional: [URLQueryItem] = [
            .init(name: "type", value: "random"),
            .init(name: "size", value: "20"),
        ]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == true)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(list == [SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)])
    }

    @Test("getAlbumsRandom: rethrows urlMaker throw")
    func getAlbumsRandomUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getAlbumsRandom()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getAlbumsRandom: rethrows networker throw")
    func getAlbumsRandomNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getAlbumsRandom()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getAlbumsRandom: rethrows decode error")
    func getAlbumsRandomDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getAlbumsRandom()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getAlbumsRandom: rethrows validator error")
    func getAlbumsRandomValidatorThrow() async throws {
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

    @Test("getAlbumsFor: calls url maker with action getArtist and additional, calls networker, calls validator, returns list")
    func getAlbumsFor() async throws {
        let album = SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)
        let payload = SubsonicResponse(
            subsonicResponse: ArtistResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                artist: SubsonicArtist(id: "1", name: "Name", albumCount: 1, album: [album], roles: nil, sortName: nil),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getAlbumsFor(artistId: "1")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getArtist")
        let expectedAdditional: [URLQueryItem] = [.init(name: "id", value: "1")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(list == [album])
    }

    @Test("getAlbumsFor: rethrows urlMaker throw")
    func getAlbumsForUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getAlbumsFor(artistId: "1")
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getAlbumsFor: rethrows networker throw")
    func getAlbumsForNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getAlbumsFor(artistId: "1")
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getAlbumsFor: rethrows decode error")
    func getAlbumsForDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getAlbumsFor(artistId: "1")
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getAlbumsFor: rethrows validator error")
    func getAlbumsForValidatorThrow() async throws {
        let album = SubsonicAlbum(id: "1", name: "title", sortName: nil, artist: "Artist", songCount: 10, song: nil)
        let payload = SubsonicResponse(
            subsonicResponse: ArtistResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                artist: SubsonicArtist(id: "1", name: "Name", albumCount: 1, album: [album], roles: nil, sortName: nil),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getAlbumsFor(artistId: "1")
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getArtistsBySearch: calls url maker with action search3 and additional, calls networker, calls validator, returns list")
    func getArtistsBySearch() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: [.init(id: "1", name: "Prince", albumCount: 3, album: nil, roles: ["artist"], sortName: "prince")], album: nil, song: nil),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getArtistsBySearch()
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "search3")
        let expectedAdditional: [URLQueryItem] = [
            .init(name: "query", value: ""),
            .init(name: "songCount", value: "0"),
            .init(name: "albumCount", value: "0"),
            .init(name: "artistCount", value: "500"),
            .init(name: "artistOffset", value: "0"),
        ]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == true)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(list == [SubsonicArtist(id: "1", name: "Prince", albumCount: 3, album: nil, roles: ["artist"], sortName: "prince")])
    }

    @Test("getArtistsBySearch: paginates with chunk 500")
    func getArtistsBySearchPaginate() async throws {
        let payload1 = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: Array(repeating: SubsonicArtist(id: "1", name: "Prince", albumCount: 3, album: nil, roles: ["artist"], sortName: "prince"),
                                                          count: 500), album: nil, song: nil),
                error: nil
            )
        )
        let payload2 = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: Array(repeating: SubsonicArtist(id: "1", name: "Prince", albumCount: 3, album: nil, roles: ["artist"], sortName: "prince"),
                                                          count: 2), album: nil, song: nil),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload1), try! JSONEncoder().encode(payload2)]
        let list = try await subject.getArtistsBySearch()
        #expect(list.count == 502)
    }

    @Test("getArtistsBySearch: rethrows urlMaker throw")
    func getArtistsBySearchUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getArtistsBySearch()
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getArtistsBySearch: rethrows networker throw")
    func getArtistsBySearchNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getArtistsBySearch()
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getArtistsBySearch: rethrows decode error")
    func getArtistsBySearchDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getArtistsBySearch()
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getArtistsBySearch: rethrows validator error")
    func getArtistsBySearchValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: [.init(id: "1", name: "Prince", albumCount: 3, album: nil, roles: ["artist"], sortName: "prince")], album: nil, song: nil),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getArtistsBySearch()
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("getSongsBySearch: calls url maker with action search3 and additional, calls networker, calls validator, returns list")
    func getSongsBySearch() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: nil, album: nil, song: [.init(id: "1", title: "Song", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getSongsBySearch(query: "Matt")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "search3")
        let expectedAdditional: [URLQueryItem] = [
            .init(name: "query", value: "Matt"),
            .init(name: "albumCount", value: "0"),
            .init(name: "artistCount", value: "0"),
            .init(name: "songCount", value: "500"),
            .init(name: "songOffset", value: "0"),
        ]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == true)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
        #expect(list == [.init(id: "1", title: "Song", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)])
    }

    @Test("getSongsBySearch: paginates with chunk 500")
    func getSongsBySearchPaginate() async throws {
        let payload1 = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: nil, album: nil, song: Array(repeating: .init(id: "1", title: "Song", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil),
                                                                                 count: 500)),
                error: nil
            )
        )
        let payload2 = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: nil, album: nil, song: Array(repeating: .init(id: "1", title: "Song", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil),
                                                                                 count: 2)),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload1), try! JSONEncoder().encode(payload2)]
        let list = try await subject.getSongsBySearch(query: "Matt")
        #expect(list.count == 502)
    }

    @Test("getSongsBySearch: rethrows urlMaker throw")
    func getSongsBySearchUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.getSongsBySearch(query: "Matt")
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("getSongsBySearch: rethrows networker throw")
    func getSongsBySearchNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.getSongsBySearch(query: "Matt")
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("getSongsBySearch: rethrows decode error")
    func getSongsBySearchDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.getSongsBySearch(query: "Matt")
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("getSongsBySearch: rethrows validator error")
    func getSongsBySearchValidatorThrow() async throws {
        let payload = SubsonicResponse(
            subsonicResponse: Search3Response(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                searchResult3: SearchResult(artist: nil, album: nil, song: [.init(id: "1", title: "Song", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)]),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.getSongsBySearch(query: "Matt")
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
                        duration: nil,
                        contributors: nil
                    )]
                ),
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let list = try await subject.getSongsFor(albumId: "1")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "getAlbum")
        let expectedAdditional: [URLQueryItem] = [.init(name: "id", value: "1")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
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
                    duration: nil,
                    contributors: nil
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
                        duration: nil,
                        contributors: nil
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
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "download")
        let expectedAdditional: [URLQueryItem] = [.init(name: "id", value: "1")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
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
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "stream")
        let expectedAdditional: [URLQueryItem] = [.init(name: "id", value: "1")]
        let additional = try #require(urlMaker.additional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(additional == expectedAdditional)
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

    @Test("jukebox: start uses start action")
    func jukeboxStart() async throws {
        let status = JukeboxStatus(currentIndex: 0, playing: false, gain: 1)
        let payload = SubsonicResponse(
            subsonicResponse: JukeboxResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                jukeboxStatus: status,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let result = try await subject.jukebox(action: .start)
        #expect(result == status)
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "jukeboxControl")
        let expectedAdditional: [URLQueryItem] = [.init(name: "action", value: "start")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
    }

    @Test("jukebox: stop uses stop action")
    func jukeboxStop() async throws {
        let status = JukeboxStatus(currentIndex: 0, playing: false, gain: 1)
        let payload = SubsonicResponse(
            subsonicResponse: JukeboxResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                jukeboxStatus: status,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let result = try await subject.jukebox(action: .stop)
        #expect(result == status)
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "jukeboxControl")
        let expectedAdditional: [URLQueryItem] = [.init(name: "action", value: "stop")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
    }

    @Test("jukebox: clear uses clear action")
    func jukeboxClear() async throws {
        let status = JukeboxStatus(currentIndex: 0, playing: false, gain: 1)
        let payload = SubsonicResponse(
            subsonicResponse: JukeboxResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                jukeboxStatus: status,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let result = try await subject.jukebox(action: .clear)
        #expect(result == status)
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "jukeboxControl")
        let expectedAdditional: [URLQueryItem] = [.init(name: "action", value: "clear")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
    }

    @Test("jukebox: add uses add action with id")
    func jukeboxAdd() async throws {
        let status = JukeboxStatus(currentIndex: 0, playing: false, gain: 1)
        let payload = SubsonicResponse(
            subsonicResponse: JukeboxResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                jukeboxStatus: status,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        let result = try await subject.jukebox(action: .add, songId: "1")
        #expect(result == status)
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "jukeboxControl")
        let expectedAdditional: [URLQueryItem] = [
            .init(name: "action", value: "add"),
            .init(name: "id", value: "1"),
        ]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
        #expect(responseValidator.methodsCalled == ["validateResponse(_:)"])
    }

    @Test("jukebox: rethrows urlMaker throw")
    func jukeboxUrlMakerThrow() async throws {
        urlMaker.errorToThrow = NetworkerError.message("oops")
        await #expect {
            try await subject.jukebox(action: .clear)
        } throws: { error in
            error as! NetworkerError == .message("oops")
        }
    }

    @Test("jukebox: rethrows networker throw")
    func jukeboxNetworkerThrow() async throws {
        networker.errorToThrow = NetworkerError.message("darn")
        await #expect {
            try await subject.jukebox(action: .clear)
        } throws: { error in
            error as! NetworkerError == .message("darn")
        }
    }

    @Test("jukebox: rethrows decode error")
    func jukeboxDecoderThrow() async throws {
        networker.dataToReturn = [try! JSONEncoder().encode(#"{"howdy": "hey"}"#)]
        await #expect {
            try await subject.jukebox(action: .clear)
        } throws: { error in
            error is DecodingError
        }
    }

    @Test("jukebox: rethrows validator error")
    func jukeboxValidatorThrow() async throws {
        let status = JukeboxStatus(currentIndex: 0, playing: false, gain: 1)
        let payload = SubsonicResponse(
            subsonicResponse: JukeboxResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                jukeboxStatus: status,
                error: nil
            )
        )
        networker.dataToReturn = [try! JSONEncoder().encode(payload)]
        responseValidator.errorToThrow = NetworkerError.message("yipes")
        await #expect {
            try await subject.jukebox(action: .clear)
        } throws: { error in
            error as! NetworkerError == .message("yipes")
        }
    }

    @Test("scrobble: calls url maker with action scrobble and additional id")
    func scrobble() async throws {
        try await subject.scrobble(songId: "4")
        #expect(urlMaker.methodsCalled == ["urlFor(action:additional:folderRestrictable:)"])
        #expect(urlMaker.action == "scrobble")
        let expectedAdditional: [URLQueryItem] = [.init(name: "id", value: "4")]
        let additional = try #require(urlMaker.additional)
        #expect(additional == expectedAdditional)
        #expect(urlMaker.folderRestrictable == false)
        #expect(networker.methodsCalled == ["performRequest(url:)"])
    }
}
