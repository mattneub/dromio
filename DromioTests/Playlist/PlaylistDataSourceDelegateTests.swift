@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PlaylistDataSourceDelegateTests {
    var subject: PlaylistDataSourceDelegate!
    let tableView = UITableView()
    let processor = MockProcessor<PlaylistAction, PlaylistState, PlaylistEffect>()

    init() {
        subject = .init(tableView: tableView)
        subject.processor = processor
    }

    @Test("initializer: creates and sets the data source, sets the delegate")
    func initializer() async throws {
        await #while(subject.datasource == nil)
        #expect(subject.datasource != nil)
        #expect(tableView.dataSource === subject.datasource)
        #expect(tableView.delegate === subject)
        #expect(subject.tableView === tableView)
    }

    @Test("receive progress: sets the `progress` of the thermometer view in the corresponding cell")
    func receiveProgress() async throws {
        makeWindow(view: tableView)
        var state = PlaylistState()
        state.songs = [.init(
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
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        // that was prep, this is the test
        subject.receive(.progress("1", 0.5))
        let thermometerView = try #require((cell?.contentView as? PlaylistCellContentView)?.thermometer)
        #expect(thermometerView.progress == 0.5)
    }

    @Test("present: datasource reflects `songs`")
    func presentWithDataDatasourceItems() async {
        var state = PlaylistState()
        state.songs = [.init(
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
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 1)
        #expect(snapshot.itemIdentifiers.first == "1")
    }

    @Test("present: cells are correctly populated")
    func presentWithDataCell() async throws {
        makeWindow(view: tableView)
        var state = PlaylistState()
        state.songs = [.init(
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
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? PlaylistCellContentConfiguration)
        let expected = PlaylistCellContentConfiguration(song: .init(
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
        ), currentSongId: nil)
        #expect(configuration == expected)
        let thermometerView = try #require((cell?.contentView as? PlaylistCellContentView)?.thermometer)
        #expect(thermometerView.progress == 0)
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .background)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
    }

    @Test("present: state currentSongId is passed to configuration")
    func presentWithCurrentItemCell() async throws {
        makeWindow(view: tableView)
        var state = PlaylistState()
        state.songs = [.init(
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
        state.currentSongId = "10"
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? PlaylistCellContentConfiguration)
        let expected = PlaylistCellContentConfiguration(song: .init(
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
        ), currentSongId: "10")
        #expect(configuration == expected)
        let thermometerView = try #require((cell?.contentView as? PlaylistCellContentView)?.thermometer)
        #expect(thermometerView.progress == 0)
    }

    @Test("present: if a song's `downloaded` is true, its cell thermometer view gets a `progress` of 1")
    func presentWithDataDownloaded() async throws {
        makeWindow(view: tableView)
        var state = PlaylistState()
        state.songs = [.init(
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
            contributors: nil,
            downloaded: true
        )]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        let configuration = try #require(cell?.contentConfiguration as? PlaylistCellContentConfiguration)
        let expected = PlaylistCellContentConfiguration(song: .init(
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
        ))
        #expect(configuration == expected)
        let thermometerView = try #require((cell?.contentView as? PlaylistCellContentView)?.thermometer)
        #expect(thermometerView.progress == 1)
    }

    @Test("didSelect: sends tapped to processor")
    func didSelect() async {
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
        makeWindow(view: tableView)
        var state = PlaylistState()
        state.songs = [song]
        subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.contains(.tapped(song)))
    }
}
