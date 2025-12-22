@testable import Dromio
import Testing
import UIKit

struct ArtistsCellContentConfigurationTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let configuration = ArtistsCellContentConfiguration(artist: SubsonicArtist(
            id: "1",
            name: "Name",
            albumCount: 100,
            album: nil,
            roles: [],
            sortName: nil
        ))
        let subject = ArtistsCellContentView(configuration)
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 2)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 2)
    }

    @Test("Applying configuration to content view configures the displayed content correctly")
    func applyConfiguration() throws {
        let configuration = ArtistsCellContentConfiguration(artist: SubsonicArtist(
            id: "1",
            name: "Name",
            albumCount: 100,
            album: nil,
            roles: [],
            sortName: nil
        ))
        let subject = ArtistsCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        var labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Name", "100\nalbums"]))
        let configuration2 = ArtistsCellContentConfiguration(artist: SubsonicArtist(
            id: "1",
            name: "Name",
            albumCount: nil,
            album: nil,
            roles: [],
            sortName: nil
        ))
        subject.configuration = configuration2
        labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Name", " \n "]))
    }

    @Test("if composer is true, album count is always suppressed")
    func applyConfigurationComposer() throws {
        let configuration = ArtistsCellContentConfiguration(artist: SubsonicArtist(
            id: "1",
            name: "Name",
            albumCount: 100,
            album: nil,
            roles: [],
            sortName: nil
        ), composer: true)
        let subject = ArtistsCellContentView(configuration)
        let loadedView = try #require(subject.subviews.first)
        let labelTexts = loadedView.subviews.filter { $0 is UILabel }.map { ($0 as? UILabel)?.text ?? "" }
        #expect(Set(labelTexts) == Set(["Name", " \n "]))
    }
}
