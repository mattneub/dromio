@testable import Dromio
import Testing
import UIKit
import WaitWhile

@MainActor
struct PlaylistDataSourceDelegateTests {
    var subject: PlaylistDataSourceDelegate!
    let tableView = UITableView()
    let processor = MockProcessor<PlaylistAction, PlaylistState, PlaylistEffect>()
    let player = MockPlayer()

    init() {
        subject = .init(tableView: tableView)
        subject.processor = processor
        services.player = player
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
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        await #while(tableView.cellForRow(at: .init(row: 0, section: 0)) == nil)
        let cell = tableView.cellForRow(at: .init(row: 0, section: 0))
        // that was prep, this is the test
        subject.receive(.progress("1", 0.5))
        let thermometerView = try #require((cell?.contentView as? PlaylistCellContentView)?.thermometer)
        #expect(thermometerView.progress == 0.5)
    }

    @Test("present: datasource reflects `songs`", arguments: [true, false])
    func presentWithDataDatasourceItems(animate: Bool) async {
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
        state.animate = animate
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 1)
        #expect(snapshot.itemIdentifiers.first == "1")
    }

    @Test("present: if the state says not to update the table view, datasource does _not_ reflect songs", arguments: [true, false])
    func presentNoUpdateTableView(animate: Bool) async {
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
        state.animate = animate
        state.updateTableView = false
        await subject.present(state)
        try? await Task.sleep(for: .seconds(0.3))
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers.count == 0)
    }

    @Test("present: cells are correctly populated", arguments: [true, false])
    func presentWithDataCell(animate: Bool) async throws {
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
        state.animate = animate
        await subject.present(state)
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

    @Test("present: state currentSongId is passed to configuration", arguments: [true, false])
    func presentWithCurrentItemCell(animate: Bool) async throws {
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
        state.animate = animate
        await subject.present(state)
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

    @Test("present: if a song's `downloaded` is true, its cell thermometer view gets a `progress` of 1, different background", arguments: [true, false])
    func presentWithDataDownloaded(animate: Bool) async throws {
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
        state.animate = animate
        await subject.present(state)
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
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == ThermometerView.thermometerFillColor)
        cell?.isSelected = true
        #expect(cell?.backgroundConfiguration?.backgroundColorTransformer?.transform(.white) == .systemGray3)
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
        await subject.present(state)
        await #while(subject.datasource.itemIdentifier(for: .init(row: 0, section: 0)) == nil)
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.contains(.tapped(song)))
    }

    @Test("trailingSwipeActions: delete button, calls processor delete with specified row")
    func trailing() async throws {
        let configuration = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 0))
        let realConfiguration = try #require(configuration)
        #expect(realConfiguration.actions.count == 1)
        #expect(realConfiguration.actions[0].image == UIImage(systemName: "trash"))
        #expect(realConfiguration.actions[0].style == .destructive)
        #expect(realConfiguration.actions[0].title == nil)
        #expect(realConfiguration.performsFirstActionWithFullSwipe == true)
        var resultOK: Bool?
        realConfiguration.actions[0].handler(
            UIContextualAction(),
            UIView(),
            { ok in resultOK = ok}
        )
        #expect(resultOK == true)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .delete(1))
    }

    @Test("moveRow: tells the processor to move row with the specified rows")
    func moveRow() async throws {
        subject.datasource.tableView(tableView, moveRowAt: .init(row: 1, section: 0), to: .init(row: 2, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .move(from: 1, to: 2))
    }

    @Test("canEdit: returns false iff player is playing")
    func canEdit() {
        do {
            player.playerStatePublisher.value = .empty
            let result = subject.datasource.tableView(tableView, canEditRowAt: .init(row: 0, section: 0))
            #expect(result == true)
        }
        do {
            player.playerStatePublisher.value = .paused
            let result = subject.datasource.tableView(tableView, canEditRowAt: .init(row: 0, section: 0))
            #expect(result == true)
        }
        do {
            player.playerStatePublisher.value = .playing
            let result = subject.datasource.tableView(tableView, canEditRowAt: .init(row: 0, section: 0))
            #expect(result == false)
        }
    }
}
