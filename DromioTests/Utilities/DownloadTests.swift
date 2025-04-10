@testable import Dromio
import Testing
import Foundation

@Suite("download tests", .fileCleanup)
@MainActor
struct DownloadTests {
    let requestMaker = MockRequestMaker()
    let mockFileManager = MockFileManager()

    init() {
        services.requestMaker = requestMaker
    }

    @Test("downloadsDirectory is Caches")
    func downloadsDirectory() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let url = await subject.downloadsDirectory()
        #expect(url.lastPathComponent == "Caches")
    }

    @Test("download: song without a suffix throws")
    func downloadNoSuffix() async throws {
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
            duration: nil,
            contributors: nil
        )
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        await #expect {
            try await subject.download(song: song)
        } throws: { error in
            error is DownloadError
        }
    }

    @Test("download: song already in cache, by id and suffix, returns its url")
    func downloadSongExists() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("1.mp3")
        let notfile = url.appendingPathComponent("2.mp3") // teehee
        mockFileManager.urls = [url: [notfile, file]]
        let result = try await subject.download(song: song)
        #expect(mockFileManager.methodsCalled == ["contentsOfDirectory(at:includingPropertiesForKeys:options:)"])
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(result.lastPathComponent == "1.mp3")
        #expect(result.deletingLastPathComponent().lastPathComponent == "Caches")
    }

    @Test("download: song not already in cache, downloads, names by id and suffix, moves, returns its url")
    func downloadSongNotExists() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        let file = URL.temporaryDirectory.appendingPathComponent("howdy")
        // we still have to write an actual file into tmp, because we're going to use URL.resourceValues to rename it
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        requestMaker.downloadURL = file
        mockFileManager.urls = [URL.temporaryDirectory: [file]]
        let result = try await subject.download(song: song)
        #expect(requestMaker.methodsCalled == ["download(songId:)"])
        #expect(requestMaker.songId == "1")
        #expect(mockFileManager.methodsCalled == ["contentsOfDirectory(at:includingPropertiesForKeys:options:)", "moveItem(at:to:)"])
        #expect(mockFileManager.moveAt?.lastPathComponent == "1.mp3")
        #expect(mockFileManager.moveAt?.deletingLastPathComponent().lastPathComponent == "tmp")
        #expect(mockFileManager.moveTo?.lastPathComponent == "1.mp3")
        #expect(mockFileManager.moveTo?.deletingLastPathComponent().lastPathComponent == "Caches")
        #expect(result.lastPathComponent == "1.mp3")
        #expect(result.deletingLastPathComponent().lastPathComponent == "Caches")
    }

    @Test("download: song not already in cache, downloads, names by id and suffix, moves — if move throws, returns tmp URL")
    func downloadSongMoveFails() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        let file = URL.temporaryDirectory.appendingPathComponent("howdy")
        // we still have to write an actual file into tmp, because we're going to use URL.resourceValues to rename it
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        requestMaker.downloadURL = file
        mockFileManager.urls = [URL.temporaryDirectory: [file]]
        mockFileManager.whatToThrow = NSError(domain: "oops", code: 0) // *
        let result = try await subject.download(song: song)
        #expect(requestMaker.methodsCalled == ["download(songId:)"])
        #expect(requestMaker.songId == "1")
        #expect(mockFileManager.methodsCalled == ["contentsOfDirectory(at:includingPropertiesForKeys:options:)", "moveItem(at:to:)"])
        #expect(mockFileManager.moveAt?.lastPathComponent == "1.mp3")
        #expect(mockFileManager.moveAt?.deletingLastPathComponent().lastPathComponent == "tmp")
        #expect(mockFileManager.moveTo?.lastPathComponent == "1.mp3")
        #expect(mockFileManager.moveTo?.deletingLastPathComponent().lastPathComponent == "Caches")
        #expect(result.lastPathComponent == "1.mp3")
        #expect(result.deletingLastPathComponent().lastPathComponent == "tmp") // *
    }

    @Test("download: if requestMaker throws on download, rethrows")
    func downloadSongRequestMakerError() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        let file = URL.temporaryDirectory.appendingPathComponent("howdy")
        requestMaker.downloadURL = file
        requestMaker.pingError = DownloadError.ranOutOfTime
        async #expect {
            try await subject.download(song: song)
        } throws: { error in
            error as! DownloadError == .ranOutOfTime
        }
    }

    @Test("clear: empties the caches directory and the temporary directory")
    func clear() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        do { // two files in caches, none in temp
            let url = await subject.downloadsDirectory()
            let file = url.appendingPathComponent("test.txt")
            let file2 = url.appendingPathComponent("test2.txt")
            mockFileManager.urls = [url: [file, file2]]
            await subject.clear()
            #expect(mockFileManager.methodsCalled == [
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
                "removeItem(at:)",
                "removeItem(at:)",
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
            ])
            #expect(mockFileManager.removeAt == [file, file2])
        }
        mockFileManager.methodsCalled = []
        mockFileManager.removeAt = []
        do { // two files in temp, none in caches
            let url = URL.temporaryDirectory
            let file = url.appendingPathComponent("test.txt")
            let file2 = url.appendingPathComponent("test2.txt")
            mockFileManager.urls = [url: [file, file2]]
            await subject.clear()
            #expect(mockFileManager.methodsCalled == [
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
                "removeItem(at:)",
                "removeItem(at:)",
            ])
            #expect(mockFileManager.removeAt == [file, file2])
        }
        mockFileManager.methodsCalled = []
        mockFileManager.removeAt = []
        do { // one file in temp and one file in caches
            let url1 = URL.temporaryDirectory
            let file1 = url1.appendingPathComponent("test.txt")
            mockFileManager.urls = [url1: [file1]]
            let url2 = await subject.downloadsDirectory()
            let file2 = url2.appendingPathComponent("test2.txt")
            mockFileManager.urls[url2] = [file2]
            await subject.clear()
            #expect(mockFileManager.methodsCalled == [
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
                "removeItem(at:)",
                "contentsOfDirectory(at:includingPropertiesForKeys:options:)",
                "removeItem(at:)",
            ])
            #expect(mockFileManager.removeAt == [file2, file1])
        }

    }

    @Test("downloadedURL(for:): returns URL if file for song exists in downloads dir, nil if not")
    func downloadedURL() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("1.mp3")
        mockFileManager.urls = [url: [file]]
        var song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        #expect(try await subject.downloadedURL(for: song) != nil)
        song = SubsonicSong(
            id: "2", // wrong id
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        #expect(try await subject.downloadedURL(for: song) == nil)
        song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "m4a", // wrong suffix
            duration: nil,
            contributors: nil
        )
        #expect(try await subject.downloadedURL(for: song) == nil)
    }

    @Test("isDownloaded: behaves as expected")
    func isDownloaded() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("1.mp3")
        mockFileManager.urls = [url: [file]]
        var song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        #expect(await subject.isDownloaded(song: song) == true)
        song = SubsonicSong(
            id: "2", // wrong id
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        #expect(await subject.isDownloaded(song: song) == false)
        song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "m4a", // wrong suffix
            duration: nil,
            contributors: nil
        )
        #expect(await subject.isDownloaded(song: song) == false)
    }

    @Test("delete: deletes the given song's file; if there is no such file, no attempt to delete")
    func delete() async throws {
        let subject = Download()
        await subject.setFileManagerProvider(provider: { mockFileManager })
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("2.mp3")
        mockFileManager.urls = [url: [file]]
        var song = SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        await(try subject.delete(song: song))
        #expect(mockFileManager.methodsCalled == ["contentsOfDirectory(at:includingPropertiesForKeys:options:)"])
        mockFileManager.methodsCalled = []
        song = SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: "mp3",
            duration: nil,
            contributors: nil
        )
        await(try subject.delete(song: song))
        #expect(mockFileManager.methodsCalled == ["contentsOfDirectory(at:includingPropertiesForKeys:options:)", "removeItem(at:)"])
    }
}
