@testable import Dromio
import Testing
import UIKit

@MainActor
struct PlaylistCellContentConfigurationTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let configuration = PlaylistCellContentConfiguration(song: SubsonicSong(
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
        ))
        let subject = PlaylistCellContentView(configuration)
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 5)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 5)
    }

    @Test("Applying configuration to content view configures the displayed content correctly")
    func applyConfiguration() throws {
        let configuration = PlaylistCellContentConfiguration(song: SubsonicSong(
            id: "1",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "Me",
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 120 // test duration formatting
        ))
        let subject = PlaylistCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        var labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Title", "2:00", "Album", "Artist", "Me"]))
        let configuration2 = PlaylistCellContentConfiguration(song: SubsonicSong(
            id: "2",
            title: "Title",
            album: "Album",
            artist: "Artist",
            displayComposer: "", // test empty composer
            track: 1,
            year: 1970,
            albumId: "2",
            suffix: nil,
            duration: 12000 // big durations get hours
        ))
        subject.configuration = configuration2
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Title", "3:20:00", "Album", "Artist", " "]))
    }
}
