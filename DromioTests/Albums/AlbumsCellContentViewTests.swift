@testable import Dromio
import Testing
import UIKit

@MainActor
struct AlbumsCellContentConfigurationTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let configuration = AlbumsCellContentConfiguration(album: SubsonicAlbum(
            id: "1",
            name: "Title",
            sortName: nil,
            artist: "Artist",
            songCount: 100,
            song: []
        ))
        let subject = AlbumsCellContentView(configuration)
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 3)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 3)
    }

    @Test("Applying configuration to content view configures the displayed content correctly")
    func applyConfiguration() throws {
        let configuration = AlbumsCellContentConfiguration(album: SubsonicAlbum(
            id: "1",
            name: "Title",
            sortName: nil,
            artist: "Artist",
            songCount: 100,
            song: []
        ))
        let subject = AlbumsCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        var labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Title", "Artist", "100\ntracks"]))
        let configuration2 = AlbumsCellContentConfiguration(album: SubsonicAlbum(
            id: "2",
            name: "Howdy",
            sortName: nil,
            artist: nil, // test nil artist
            songCount: 1, // test singular/plural
            song: []
        ))
        subject.configuration = configuration2
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Howdy", " ", "1\ntrack"]))
    }
}
