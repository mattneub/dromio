@testable import Dromio
import Testing
import UIKit

@MainActor
struct AlbumCellContentConfigurationTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let configuration = AlbumCellContentConfiguration(song: SubsonicSong(
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
        ), totalCount: 10)
        let subject = AlbumCellContentView(configuration)
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 5)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 5)
    }

    @Test("Applying configuration to content view configures the displayed content correctly")
    func applyConfiguration() throws {
        let configuration = AlbumCellContentConfiguration(song: SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 120, // test duration formatting
            contributors: nil
        ), totalCount: 10)
        let subject = AlbumCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        var labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Title", "Artist", "1 of 10", "Me 1970", "2:00"]))
        let configuration2 = AlbumCellContentConfiguration(song: SubsonicSong(
            id: "2",
            title: "Howdy",
            album: "Hey",
            artist: "Rembrandt",
            displayComposer: "", // test empty composer
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 120,
            contributors: nil
        ), totalCount: 10)
        subject.configuration = configuration2
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Howdy", "Rembrandt", "1 of 10", "1970", "2:00"]))
        let configuration3 = AlbumCellContentConfiguration(song: SubsonicSong(
            id: "3",
            title: "Howdy",
            album: "Hey",
            artist: "Rembrandt",
            displayComposer: "Me",
            track: 1,
            year: nil, // test empty year
            albumId: "2",
            suffix: nil,
            duration: 120,
            contributors: nil
        ), totalCount: 10)
        subject.configuration = configuration3
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Howdy", "Rembrandt", "1 of 10", "Me  ", "2:00"]))
        let configuration4 = AlbumCellContentConfiguration(song: SubsonicSong(
            id: "4",
            title: "Howdy",
            album: "Hey",
            artist: nil, // test empty artist
            displayComposer: "", // test empty composer and year
            track: nil, // test empty track
            year: nil,
            albumId: "2",
            suffix: nil,
            duration: 120,
            contributors: nil
        ), totalCount: 10)
        subject.configuration = configuration4
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Howdy", " ", "0 of 10", " ", "2:00"]))
    }
}
