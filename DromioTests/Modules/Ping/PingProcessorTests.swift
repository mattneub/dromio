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
    let download = MockDownload()
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
        requestMaker.user = .init(adminRole: true, scrobblingEnabled: false, downloadRole: true, streamRole: true, jukeboxRole: true)
        subject.cycler = MockCycler(processor: subject)
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
        #expect(coordinator.options == ["u@h:1"])
        #expect(!persistence.methodsCalled.contains("save(servers:)"))
        #expect(!persistence.methodsCalled.contains("save(currentFolder:)"))
    }

    @Test("receive deleteServer: if servers, call coordinator showActionSheet, deletes given server from servers list")
    func receiveDeleteServerNotNil() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "u@h:1"
        await subject.receive(.deleteServer)
        #expect(coordinator.methodsCalled.last == "showActionSheet(title:options:)")
        #expect(coordinator.title == "Pick a server to delete:")
        #expect(coordinator.options == ["u@h:1", "uu@hh:1"])
        #expect(persistence.methodsCalled.contains("save(servers:)"))
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ])
    }

    @Test("receive deleteServer: if deletes first server, disables pick folder button, set current folder to nil")
    func receiveDeleteServerDeletedFirst() async {
        persistence.currentFolder = 100
        subject.state.enablePickFolderButton = true
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "u@h:1"
        await subject.receive(.deleteServer)
        #expect(presenter.statePresented?.enablePickFolderButton == false)
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == nil)
    }

    @Test("receive deleteServer: if deletes non-first server, doesn't disable pick folder button, doesn't change current folder")
    func receiveDeleteServerDeletedNonFirst() async {
        persistence.currentFolder = 100
        subject.state.enablePickFolderButton = true
        persistence.servers = [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "u@h:1"
        await subject.receive(.deleteServer)
        #expect(subject.state.enablePickFolderButton == true)
        #expect(presenter.statePresented == nil)
        #expect(!persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == 100)
    }

    @Test("receive doPing: sets status to empty; if current server is nil, tries to load the server")
    func receiveDoPingNilCurrentServer() async {
        await subject.receive(.doPing())
        #expect(presenter.statesPresented.first?.status == .empty)
        #expect(persistence.methodsCalled[0] == "loadServers()")
    }

    @Test("receive doPing: if current server is nil, and there is no stored server, shows the server interface")
    func receiveDoPingNilCurrentServerNoStored() async {
        await subject.receive(.doPing())
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
        await subject.receive(.doPing())
        #expect(!coordinator.methodsCalled.contains("showServer(delegate:)"))
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"))
    }

    @Test("receive doPing: with current server sets status to unknown, calls networker ping")
    func receiveDoPing() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(presenter.statesPresented[1].status == .unknown)
    }

    @Test("receive doPing: with no ping issues call networker getUser, sets global user jukebox info, calls networker getFolders")
    func receiveDoPingGetUser() async {
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
        #expect(subject.state.folders == [])
    }

    @Test("receive doPing: with no ping issues calls networker getFolders, sets folder globals")
    func receiveDoPingGetFolders() async {
        persistence.currentFolder = 100
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let returnedFolders: [SubsonicFolder] = [.init(id: 1, name: "One"), .init(id: 2, name: "Two")]
        requestMaker.folderList = returnedFolders
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
        #expect(subject.state.folders == returnedFolders)
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == nil)
        #expect(presenter.statePresented?.enablePickFolderButton == true)
    }

    @Test("receive doPing: with no ping issues calls networker getFolders, if fewer than two, no pick folder button enablement")
    func receiveDoPingGetFoldersFewer() async {
        persistence.currentFolder = 100
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let returnedFolders: [SubsonicFolder] = [.init(id: 1, name: "One")]
        requestMaker.folderList = returnedFolders
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
        #expect(subject.state.folders == returnedFolders)
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == nil)
        #expect(presenter.statePresented?.enablePickFolderButton == false) // *
    }

    @Test("receive doPing: with no ping issues calls networker getFolders, if restricted folder, sets current folder")
    func receiveDoPingGetFoldersRestricted() async {
        persistence.currentFolder = 100
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let returnedFolders: [SubsonicFolder] = [.init(id: 1, name: "One")]
        requestMaker.folderList = returnedFolders
        await subject.receive(.doPing(1)) // *
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
        #expect(subject.state.folders == returnedFolders)
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == 1) // *
        #expect(presenter.statePresented?.enablePickFolderButton == false)
    }

    @Test("receive doPing: with no ping issues calls networker getFolders, if restricted folder bad, sets current folder to nil")
    func receiveDoPingGetFoldersRestrictedBad() async {
        persistence.currentFolder = 100
        userHasJukeboxRole = false
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let returnedFolders: [SubsonicFolder] = [.init(id: 2, name: "Two")]
        requestMaker.folderList = returnedFolders
        await subject.receive(.doPing(1)) // *
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == true)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
        #expect(subject.state.folders == returnedFolders)
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == nil) // *
        #expect(presenter.statePresented?.enablePickFolderButton == false)
    }

    @Test("receive doPing: sets global user jukebox info to false if user not admin")
    func receiveDoPingGetUserNotAdmin() async {
        userHasJukeboxRole = true
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.user = .init(adminRole: false, scrobblingEnabled: true, downloadRole: true, streamRole: true, jukeboxRole: true)
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == false)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
    }

    @Test("receive doPing: sets global user jukebox info to false if user not jukebox")
    func receiveDoPingGetUserNotJukebox() async {
        userHasJukeboxRole = true
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.user = .init(adminRole: true, scrobblingEnabled: true, downloadRole: true, streamRole: true, jukeboxRole: false)
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(userHasJukeboxRole == false)
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
    }

    @Test("receive doPing: with no issues call networker getUser, barfs if user cannot stream and download")
    func receiveDoPingGetUserNoDownload() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        requestMaker.user = .init(adminRole: true, scrobblingEnabled: false, downloadRole: false, streamRole: true, jukeboxRole: true)
        await subject.receive(.doPing())
        #expect(presenter.statePresented?.status == .failure(message: "User needs stream and download privileges."))
        #expect(coordinator.methodsCalled.isEmpty)
        requestMaker.user = .init(adminRole: true, scrobblingEnabled: false, downloadRole: true, streamRole: false, jukeboxRole: true)
        await subject.receive(.doPing())
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
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled[0] == "ping()")
        #expect(requestMaker.methodsCalled[1] == "getUser()")
        #expect(requestMaker.methodsCalled[2] == "getFolders()")
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
        await subject.receive(.doPing())
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
        await subject.receive(.doPing())
        #expect(requestMaker.methodsCalled == ["ping()"])
        #expect(presenter.statePresented?.status == .failure(message: "oops"))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("receive launch: fetches current folder from persistence, calls .doPing")
    func receiveLaunch() async throws {
        persistence.currentFolder = 2
        await subject.receive(.launch)
        #expect(persistence.methodsCalled.first == "loadCurrentFolder()")
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing(2)])
    }

    @Test("receive launch: fetches current folder from persistence, calls .doPing")
    func receiveLaunchNil() async throws {
        persistence.currentFolder = nil
        await subject.receive(.launch)
        #expect(persistence.methodsCalled.first == "loadCurrentFolder()")
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing(nil)])
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

    @Test("receive pickFolder: calls showActionSheet, if nil response, stops", .mockCache)
    func pickFolderNoChoice() async throws {
        subject.state.folders = [.init(id: 1, name: "One"), .init(id: 2, name: "Two")]
        await subject.receive(.pickFolder)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a library to use:")
        #expect(coordinator.options == ["One", "Two", "Use All Libraries"])
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled.isEmpty)
    }

    @Test("receive pickFolder: if response is Use All Libraries, clear the cache, save nil, send .doPing", .mockCache)
    func pickFolderUseAll() async throws {
        persistence.currentFolder = 100
        subject.state.folders = [.init(id: 1, name: "One"), .init(id: 2, name: "Two")]
        coordinator.optionToReturn = "Use All Libraries"
        await subject.receive(.pickFolder)
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"])
        #expect(persistence.methodsCalled.first == "save(currentFolder:)")
        #expect(persistence.currentFolder == nil)
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing()])
    }

    @Test("receive pickFolder: if response is bad value, clear the cache, save nil, send .doPing", .mockCache)
    func pickFolderBadValue() async throws {
        persistence.currentFolder = 100
        subject.state.folders = [.init(id: 1, name: "One"), .init(id: 2, name: "Two")]
        coordinator.optionToReturn = "Bad Value"
        await subject.receive(.pickFolder)
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"])
        #expect(persistence.methodsCalled.first == "save(currentFolder:)")
        #expect(persistence.currentFolder == nil)
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing()])
    }

    @Test("receive pickFolder: if response is good value, clear the cache, save value, send .doPing with id", .mockCache)
    func pickFolderGoodValue() async throws {
        persistence.currentFolder = 100
        subject.state.folders = [.init(id: 1, name: "One"), .init(id: 2, name: "Two")]
        coordinator.optionToReturn = "Two"
        await subject.receive(.pickFolder)
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"])
        await #while(persistence.methodsCalled.isEmpty)
        #expect(persistence.methodsCalled.first == "save(currentFolder:)")
        #expect(persistence.currentFolder == 2)
        let cycler = try #require(subject.cycler as? MockCycler)
        await #while(cycler.thingsReceived.isEmpty)
        #expect(cycler.thingsReceived == [.doPing(2)])
    }

    @Test("receive pickServer: if no servers, calls showAlert and stops", .mockCache)
    func pickServerNoServer() async throws {
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showAlert(title:message:)"])
        #expect(coordinator.title == "No server to choose.")
        #expect(coordinator.message == "Tap Enter Server Info if you want to add a server.")
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled.isEmpty)
    }

    @Test("receive pickServer: if servers, calls showActionSheet, if nil response, stops", .mockCache)
    func pickServerNoChoice() async throws {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a server to use:")
        #expect(coordinator.options == ["u@h:1", "uu@hh:1"])
        #expect(persistence.methodsCalled.count == 1)
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled.isEmpty)
    }

    @Test("receive pickServer: if servers, calls showActionSheet, if one is chosen, brings it to front, saves, sets current server, clears playlist and downloads, calls doPing", .mockCache)
    func pickServer() async throws {
        persistence.currentFolder = 100
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "uu@hh:1"
        urlMaker.currentServerInfo = nil
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a server to use:")
        #expect(coordinator.options == ["u@h:1", "uu@hh:1"])
        #expect(persistence.methodsCalled.contains("save(servers:)"))
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
        ])
        #expect(persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == nil)
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"))
        #expect(currentPlaylist.methodsCalled == ["clear()"])
        #expect(await download.methodsCalled == ["clear()"])
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"])
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing()])
    }

    @Test("receive pickServer: if servers, calls showActionSheet, if current one is chosen, no save, no set, no clear playlist, no clear downloads, calls doPing", .mockCache)
    func pickServerSameAsCurrentServer() async throws {
        persistence.currentFolder = 100
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        coordinator.optionToReturn = "u@h:1"
        urlMaker.currentServerInfo = ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v")
        await subject.receive(.pickServer)
        #expect(coordinator.methodsCalled == ["showActionSheet(title:options:)"])
        #expect(coordinator.title == "Pick a server to use:")
        #expect(coordinator.options == ["u@h:1", "uu@hh:1"])
        #expect(!persistence.methodsCalled.contains("save(servers:)"))
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ])
        #expect(!persistence.methodsCalled.contains("save(currentFolder:)"))
        #expect(persistence.currentFolder == 100)
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"))
        #expect(currentPlaylist.methodsCalled.isEmpty)
        #expect(await download.methodsCalled.isEmpty)
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"]) // but the cache _is_ cleared
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing(100)])
    }

    @Test("receive reenterServerInfo: calls coordinator showServer with self as delegate")
    func reenter() async {
        await subject.receive(.reenterServerInfo)
        #expect(coordinator.methodsCalled == ["showServer(delegate:)"])
        #expect(coordinator.delegate === subject)
    }

    @Test("userEdited: puts the new server info first in the list, sets the current server, clears current folder, clears current playlist and downloads, calls ping", .mockCache)
    func userEdited() async throws {
        persistence.currentFolder = 100
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let newServer = ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v")
        await subject.userEdited(serverInfo: newServer)
        #expect(persistence.methodsCalled.suffix(2) == ["save(servers:)", "save(currentFolder:)"])
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ])
        #expect(persistence.currentFolder == nil)
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hhh", port: 1, username: "uuu", password: "p", version: "v"))
        #expect(currentPlaylist.methodsCalled == ["clear()"])
        let mockCache = try #require(services.cache as? MockCache)
        #expect(mockCache.methodsCalled == ["clear()"])
        #expect(await download.methodsCalled == ["clear()"])
        let cycler = try #require(subject.cycler as? MockCycler)
        #expect(cycler.thingsReceived == [.doPing()])
    }

    @Test("userEdited: if this server was already in the list, the old version is removed")
    func userEditedAlreadyExists() async {
        persistence.servers = [
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "p", version: "v"),
        ]
        let newServer = ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v")
        await subject.userEdited(serverInfo: newServer)
        #expect(persistence.methodsCalled.suffix(2) == ["save(servers:)", "save(currentFolder:)"])
        #expect(persistence.servers == [
            ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v"),
            ServerInfo(scheme: "http", host: "h", port: 1, username: "u", password: "p", version: "v"),
        ])
        #expect(urlMaker.currentServerInfo == ServerInfo(scheme: "http", host: "hh", port: 1, username: "uu", password: "pp", version: "v"))
    }
}
