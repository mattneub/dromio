@testable import Dromio
import Testing
import Foundation

struct PingOfflineAllowerTests {
    let download = MockDownload()
    let playlist = MockPlaylist()
    let subject = PingOfflineAllower()

    init() {
        services.download = download
        services.currentPlaylist = playlist
    }

    @Test("offline allower allows offline if playlist and downloads intersect")
    func allows() async {
        playlist.list = [
            .init(id: "1", title: "1", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        ]
        download.bools["1"] = true
        #expect(await subject.canShowOfflineModeButton() == true)
    }

    @Test("offline allower forbids offline if playlist and downloads don't")
    func forbids() async {
        playlist.list = [
            .init(id: "1", title: "1", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        ]
        download.bools["2"] = true
        #expect(await subject.canShowOfflineModeButton() == false)
    }
}
