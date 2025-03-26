@testable import Dromio
import Testing
import Foundation

@MainActor
final class DownloadTests { // class, because we have cleanup to perform after each test
    let requestMaker = MockRequestMaker()

    init() {
        services.requestMaker = requestMaker
    }

    deinit {
        let fileManager = FileManager.default
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: URL.cachesDirectory,
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
        do {
            let contents: [URL] = (try? fileManager.contentsOfDirectory(
                at: URL.temporaryDirectory,
                includingPropertiesForKeys: []
            )) ?? []
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    @Test("downloadsDirectory is Caches")
    func downloadsDirectory() async throws {
        let subject = Download()
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
        await #expect {
            try await subject.download(song: song)
        } throws: { error in
            error is DownloadError
        }
    }

    @Test("download: song already in cache, by id and suffix, returns its url")
    func downloadSongExists() async throws {
        let subject = Download()
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
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        let result = try await subject.download(song: song)
        #expect(requestMaker.methodsCalled.isEmpty)
        #expect(result.lastPathComponent == "1.mp3")
        #expect(result.deletingLastPathComponent().lastPathComponent == "Caches")
    }

    @Test("download: song not already in cache, downloads, names by id and suffix, returns its url")
    func downloadSongNotExists() async throws {
        let subject = Download()
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
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        requestMaker.downloadURL = file
        let result = try await subject.download(song: song)
        #expect(requestMaker.methodsCalled == ["download(songId:)"])
        #expect(requestMaker.songId == "1")
        #expect(result.lastPathComponent == "1.mp3")
        #expect(result.deletingLastPathComponent().lastPathComponent == "Caches")
        let content = try String(contentsOf: result, encoding: .utf8)
        #expect(content == "howdy")
        // TODO: Also test what happens if `moveItem` throws
    }

    @Test("download: if requestMaker throws on download, rethrows")
    func downloadSongRequestMakerError() async throws {
        let subject = Download()
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
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        requestMaker.downloadURL = file
        requestMaker.pingError = DownloadError.ranOutOfTime
        async #expect {
            try await subject.download(song: song)
        } throws: { error in
            error as! DownloadError == .ranOutOfTime
        }
    }
    // TODO: Not testing what happens when the move to Caches fails

    @Test("clear: empties the caches directory and the temporary directory")
    func clear() async throws {
        let subject = Download()
        do {
            let url = await subject.downloadsDirectory()
            let file = url.appendingPathComponent("test.txt")
            try "howdy".write(to: file, atomically: true, encoding: .utf8)
            #expect(try file.checkResourceIsReachable())
            await subject.clear()
            #expect {
                try !file.checkResourceIsReachable()
            } throws: { error in
                error._code == 260
            }
        }
        do {
            let url = URL.temporaryDirectory
            let file = url.appendingPathComponent("test.txt")
            try "howdy".write(to: file, atomically: true, encoding: .utf8)
            #expect(try file.checkResourceIsReachable())
            await subject.clear()
            #expect {
                try !file.checkResourceIsReachable()
            } throws: { error in
                error._code == 260
            }
        }
    }

    @Test("downloadedURL(for:): returns URL if file for song exists in downloads dir, nil if not")
    func downloadedURL() async throws {
        let subject = Download()
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("1.mp3")
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
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
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("1.mp3")
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
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

    @Test("delete: deletes the given song's file; if there is no such file, no harm done")
    func delete() async throws {
        let subject = Download()
        let url = await subject.downloadsDirectory()
        let file = url.appendingPathComponent("2.mp3")
        try "howdy".write(to: file, atomically: true, encoding: .utf8)
        #expect(try file.checkResourceIsReachable())
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
        #expect(try file.checkResourceIsReachable())
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
        #expect {
            try file.checkResourceIsReachable()
        } throws: { _ in
            true
        }
    }
}
