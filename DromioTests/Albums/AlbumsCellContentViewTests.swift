@testable import Dromio
import Testing
import UIKit

@MainActor
struct AlbumsCellContentConfigurationTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let configuration = AlbumsCellContentConfiguration(
            title: "Title",
            artist: "Artist",
            tracks: 100
        )
        let subject = AlbumsCellContentView(configuration)
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 3)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 3)
    }

    @Test("Applying configuration to content view configures the displayed content correctly")
    func applyConfiguration() throws {
        var configuration = AlbumsCellContentConfiguration(
            title: "Title",
            artist: "Artist",
            tracks: 100
        )
        let subject = AlbumsCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        var labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Title", "Artist", "100\ntracks"]))
        configuration.title = "Howdy"
        configuration.artist = "Rembrandt"
        configuration.tracks = 1 // test singular/plural
        subject.configuration = configuration
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Howdy", "Rembrandt", "1\ntrack"]))
    }
}
