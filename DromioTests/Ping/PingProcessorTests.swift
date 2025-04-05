@testable import Dromio
import Testing
import Foundation
import WaitWhile

@MainActor
struct PingProcessorTests {
    let subject = PingProcessor()
    let presenter = MockReceiverPresenter<Void, PingState>()
    let requestMaker = MockRequestMaker()
    let coordinator = MockRootCoordinator()
    let urlMaker = MockURLMaker()
    let persistence = MockPersistence()
    let download = MockDownload(fileManager: MockFileManager())
    let currentPlaylist = MockPlaylist()
    let haptic = MockHaptic()
    let player = MockPlayer()

    init() {
        services.requestMaker = requestMaker
        services.urlMaker = urlMaker
        services.persistence = persistence
        services.currentPlaylist = currentPlaylist
        services.download = download
        services.haptic = haptic
        services.player = player
        subject.presenter = presenter
        subject.coordinator = coordinator
        requestMaker.user = .init(scrobblingEnabled: false, downloadRole: true, streamRole: true, jukeboxRole: true)
    }

    @Test("receive choices: sets the status to choices, clears the player")
    func receiveChoices() async {
        await subject.receive(.choices)
        #expect(presenter.statePresented?.status == .choices)
        #expect(player.methodsCalled == ["clear()"])
    }

    @Test("receive deleteServer: if no servers, calls coordinator showAlert")
    func receiveDeleteServerNoServers() async {
        await subject.receive(.deleteServer)
        #expect(coordinator.methodsCalled.last == "showAlert(title:message:)")
        #expect(coordinator.title == "Nothing to delete.")
        #expect(coordinator.message == "Tap Enter Server Info if you want to add a server.")
    }

    @Test("receive deleteServer: if servers, call coordinator showActionSheet, stops if result is nil")
    func receiveDeleteServerNil() async {
        persistence.servers = [ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v")]
        await subject.receive(.deleteServer)
        #expect(coordinator.methodsCalled.last == "showActionSheet(title:options:)")
        #expect(coordinator.title == "Pick a server to delete:")
        #expect(coordinator.options == ["u@h"])
        #expect(!persistence.methodsCalled.contains("save(servers:)"))
    }

    @Test("receive deleteServer: if servers, call coordinator showActionSheet, deletes given server from servers list")
    func receiveDeleteServerNotNil() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "u@h"
        await subject.receive(.deleteServer)
        #expect(coordinator.methodsCalled.last == "showActionSheet(title:options:)")
        #expect(coordinator.title == "Pick a server to delete:")
        #expect(coordinator.options == ["u@h", "uu@hh"])
        #expect(persistence.methodsCalled.contains("save(servers:)"))
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ])
    }

    @Test("receive doPing: sets status to empty; if current server is nil, tries to load the server")
    func receiveDoPingNilCurrentServer() async {
        await subject.receive(.doPing)
        #expect(presenter.statesPresented.first?.status == .empty)
        #expect(persistence.methodsCalled[0] == "loadServers()")
    }

    @Test("receive doPing: if current server is nil, and there is no stored server, shows the server interface")
    func receiveDoPingNilCurrentServerNoStored() async {
        await subject.receive(.doPing)
        #expect(presenter.statesPresented.first?.status == .empty)
        #expect(coordinator.methodsCalled[0] == "showServer(delegate:)")
        #expect(coordinator.delegate === subject)
    }

    @Test("receive doPing: if current server is nil, and there are stored servers, sets current server to the first one")
    func receiveDoPingNilCurrentServerStored() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.doPing)
        #expect(!coordinator.methodsCalled.contains("showServer(delegate:)"))
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"))
    }

    @Test("receive doPing: with current server sets status to unknown, calls networker ping")
    func receiveDoPing() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(presenter.statesPresented[1].status == .unknown)
    }

    @Test("receive doPing: with no ping issues call networker getUser, sets global user jukebox info")
    func receiveDoPingGetUser() async {
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
    }

    @Test("receive doPing: with no issues call networker getUser, barfs if user cannot stream and download")
    func receiveDoPingGetUserNoDownload() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.user = .init(scrobblingEnabled: false, downloadRole: false, streamRole: true, jukeboxRole: true)
        await subject.receive(.doPing)
        #expect(presenter.statePresented?.status == .failure(message: "User needs stream and download privileges."))
        #expect(coordinator.methodsCalled.isEmpty)
        requestMaker.user = .init(scrobblingEnabled: false, downloadRole: true, streamRole: false, jukeboxRole: true)
        await subject.receive(.doPing)
        #expect(presenter.statePresented?.status == .failure(message: "User needs stream and download privileges."))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive doPing: with no issues sets state status to .success if no throw and calls coordinator showAlbums")
    func receiveDoPingSuccess() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.pingError = nil
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(presenter.statePresented?.status == .success)
        #expect(coordinator.methodsCalled[0] == "showAlbums()")
    }

    @Test("receive doPing: with current server calls networker ping, sets state status to .failure and message if throw NetworkerError")
    func receiveDoPingFailure() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.pingError = NetworkerError.message("test")
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.status == .failure(message: "test"))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive doPing: with current server calls networker ping, sets state status to .failure and localized description if throw other error")
    func receiveDoPingFailure2() async {
        class MyError: NSError, @unchecked Sendable {
            override var localizedDescription: String { "oops" }
        }
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.pingError = MyError(domain: "domain", code: 0)
        await subject.receive(.doPing)
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.status == .failure(message: "oops"))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive offlineMode: intersects current playlist with downloads, balks with alert if empty")
    func offlineModePlaylistAndDownloads() async {
        currentPlaylist.list = [
            .init(id: "1", title: "1", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        ]
        download.bools["2"] = true
        await subject.receive(.offlineMode)
        #expect(coordinator.methodsCalled == ["showAlert(title:message:)"])
        #expect(coordinator.title == "No downloads to play.")
        #expect(coordinator.message == "You can’t enter offline mode, because you have no downloaded playlist items.")
    }

    @Test("receive offlineMode: if all is well, calls showPlaylist with state offlinemode")
    func offlineMode() async {
        currentPlaylist.list = [
            .init(id: "1", title: "1", album: nil, artist: nil, displayComposer: nil, track: nil, year: nil, albumId: nil, suffix: nil, duration: nil, contributors: nil)
        ]
        download.bools["1"] = true
        await subject.receive(.offlineMode)
        #expect(coordinator.methodsCalled == ["showPlaylist(state:)"])
        #expect(coordinator.playlistState == .init(offlineMode: true))
    }

    @Test("receive pickServer: if no servers, calls showAlert and stops", .mockCaches)
    func pickServerNoServer() async throws {
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showAlert(title:message:)"])
        #expect(coordinator.title == "No server to choose.")
        #expect(coordinator.message == "Tap Enter Server Info if you want to add a server.")
        let mockCaches = try #require(caches as? MockCaches)
        #expect(mockCaches.methodsCalled.isEmpty)
    }

    @Test("receive pickServer: if servers, calls showActionSheet, if nil response, stops", .mockCaches)
    func pickServerNoChoice() async throws {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a server to use:")
        #expect(coordinator.options == ["u@h", "uu@hh"])
        #expect(persistence.methodsCalled.count == 1)
        let mockCaches = try #require(caches as? MockCaches)
        #expect(mockCaches.methodsCalled.isEmpty)
    }

    @Test("receive pickServer: if servers, calls showActionSheet, if one is chosen, brings it to front, saves, sets current server, clears playlist and downloads, calls doPing", .mockCaches)
    func pickServer() async throws {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "uu@hh"
        urlMaker.currentServerInfo = nil
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a server to use:")
        #expect(coordinator.options == ["u@h", "uu@hh"])
        #expect(persistence.methodsCalled.contains("save(servers:)"))
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
        ])
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"))
        #expect(currentPlaylist.methodsCalled == ["clear()"])
        #expect(await download.methodsCalled == ["clear()"])
        let mockCaches = try #require(caches as? MockCaches)
        #expect(mockCaches.methodsCalled == ["clear()"])
        await #while(presenter.statesPresented.isEmpty)
        #expect(presenter.statesPresented.first?.status == .empty)
    }

    @Test("receive reenterServerInfo: calls coordinator showServer with self as delegate")
    func reenter() async {
        await subject.receive(.reenterServerInfo)
        #expect(coordinator.methodsCalled == ["showServer(delegate:)"])
        #expect(coordinator.delegate === subject)
    }

    @Test("userEdited: puts the new server info first in the list, sets the current server, clears current playlist and downloads, calls ping", .mockCaches)
    func userEdited() async throws {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let newServer = ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v")
        await subject.userEdited(serverInfo: newServer)
        #expect(persistence.methodsCalled.last == "save(servers:)")
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ])
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v"))
        #expect(currentPlaylist.methodsCalled == ["clear()"])
        let mockCaches = try #require(caches as? MockCaches)
        #expect(mockCaches.methodsCalled == ["clear()"])
        await #while(presenter.statesPresented.isEmpty)
        #expect(await download.methodsCalled == ["clear()"])
        #expect(presenter.statesPresented.first?.status == .empty)
    }

    @Test("userEdited: if this server was already in the list, the old version is removed")
    func userEditedAlreadyExists() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let newServer = ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v")
        await subject.userEdited(serverInfo: newServer)
        #expect(persistence.methodsCalled.last == "save(servers:)")
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
        ])
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v"))
        await #while(presenter.statesPresented.isEmpty)
        #expect(presenter.statesPresented.first?.status == .empty)
    }
}
