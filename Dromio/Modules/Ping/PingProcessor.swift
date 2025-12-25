import Foundation

/// Processor containing logic for the Ping view controller.
///
final class PingProcessor: Processor {
    /// A reference to the root coordinator, set by the coordinator on creation.
    weak var coordinator: (any RootCoordinatorType)?

    /// A reference to our presenter (the Ping view controller), set by the coordinator on creation.
    weak var presenter: (any ReceiverPresenter<Void, PingState>)?

    /// The state, to be presented by the presenter.
    var state = PingState()

    /// Cycler, so that we can dispatch actions to ourself and test that we did so.
    lazy var cycler: Cycler = Cycler(processor: self)

    func receive(_ action: PingAction) async {
        switch action {
        case .choices:
            state.status = .choices
            await presenter?.present(state)
            services.player.clear()
        case .deleteServer:
            await deleteServer()
        case .doPing(let folderId):
            await ping(restrictToFolder: folderId)
        case .launch:
            await cycler.receive(.doPing(services.persistence.loadCurrentFolder()))
        case .offlineMode:
            await offlineMode()
        case .pickFolder:
            await pickFolder()
        case .pickServer:
            await pickServer()
        case .reenterServerInfo:
            coordinator?.showServer(delegate: self)
        }
    }

    /// Utility saying what to do when we receive .doPing. Also called directly by `pickFolder`.
    /// - Parameter restrictedFolder: Folder ID to restrict to, or `nil` to mean use all libraries.
    ///
    private func ping(restrictToFolder restrictedFolder: Int? = nil) async {
        do {
            state.status = .empty
            await presenter?.present(state)
            await Task.yield()
            if services.urlMaker.currentServerInfo == nil {
                guard let server = try services.persistence.loadServers().first else {
                    coordinator?.showServer(delegate: self)
                    return
                }
                services.urlMaker.currentServerInfo = server
            }
            state.status = .unknown
            await presenter?.present(state)
            await Task.yield()
            try await services.requestMaker.ping()
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.4))
            }
            let user = try await services.requestMaker.getUser()
            guard user.downloadRole && user.streamRole else {
                throw NetworkerError.message("User needs stream and download privileges.")
            }
            userHasJukeboxRole = user.jukeboxRole && user.adminRole
            state.folders = try await services.requestMaker.getFolders() // older versions return one folder with id 1
            let currentFolder: SubsonicFolder? = state.folders.first(where: { $0.id == restrictedFolder })
            let multipleFolders = state.folders.count > 1
            services.persistence.save(currentFolder: currentFolder, suppressName: !multipleFolders)
            state.status = .success
            state.enablePickFolderButton = multipleFolders
            await presenter?.present(state)
            await Task.yield()
            try? await unlessTesting {
                try? await Task.sleep(for: .seconds(0.6))
            }
            coordinator?.showAlbums()
        } catch NetworkerError.message(let message) {
            state.status = .failure(message: message)
            await presenter?.present(state)
        } catch {
            state.status = .failure(message: error.localizedDescription)
            await presenter?.present(state)
        }
    }

    /// Utility saying what to do when we receive `.deleteServer`.
    private func deleteServer() async {
        guard var servers = try? services.persistence.loadServers() else { return }
        guard servers.count > 0 else {
            coordinator?.showAlert(title: "Nothing to delete.", message: "Tap Enter Server Info if you want to add a server.")
            return
        }

        guard let serverId = await coordinator?.showActionSheet(
            title: "Pick a server to delete:",
            options: servers.map { $0.id }
        ) else {
            return
        }

        let index = servers.firstIndex(where: { $0.id == serverId }) ?? 0
        servers.remove(at: index)
        try? services.persistence.save(servers: servers)

        if index == 0 {
            services.persistence.save(currentFolder: nil)
            state.enablePickFolderButton = false
            await presenter?.present(state)
        }
        // and stop; user cannot proceed without explicitly picking a server or folder
    }

    /// Utility saying what to do when we receive `.pickFolder`.
    private func pickFolder() async {
        let useAll = "Use All Libraries"
        guard let folderName = await coordinator?.showActionSheet(
            title: "Pick a library to use:",
            options: state.folders.map { $0.name } + [useAll]
        ) else {
            return
        }

        services.cache.clear()
        guard folderName != useAll else {
            services.persistence.save(currentFolder: nil)
            await cycler.receive(.doPing())
            return
        }
        guard let folder = state.folders.first(where: { $0.name == folderName }) else {
            services.persistence.save(currentFolder: nil)
            await cycler.receive(.doPing()) // shouldn't happen, but let's do _something_
            return
        }
        Task {
            services.persistence.save(currentFolder: folder)
            await cycler.receive(.doPing(folder.id))
        }
    }

    /// Utility saying what to do when we receive `.pickServer`.
    private func pickServer() async {
        guard var servers = try? services.persistence.loadServers() else { return }
        guard servers.count > 0 else {
            coordinator?.showAlert(title: "No server to choose.", message: "Tap Enter Server Info if you want to add a server.")
            return
        }

        guard let serverId = await coordinator?.showActionSheet(
            title: "Pick a server to use:",
            options: servers.map { $0.id }
        ) else {
            return
        }

        services.cache.clear()
        if serverId != services.urlMaker.currentServerInfo?.id { // i.e. changed servers
            let index = servers.firstIndex(where: { $0.id == serverId }) ?? 0
            let server = servers.remove(at: index)
            servers.insert(server, at: 0)
            try? services.persistence.save(servers: servers)
            services.persistence.save(currentFolder: nil)
            services.urlMaker.currentServerInfo = server
            services.currentPlaylist.clear()
            await services.download.clear()
        }
        Task {
            await cycler.receive(.doPing(services.persistence.loadCurrentFolder()))
        }
    }

    /// Utility saying what to do when we receive `.offlineMode`.
    private func offlineMode() async {
        // intersect the current playlist with downloads
        var intersection = [URL?]()
        for song in services.currentPlaylist.list {
            intersection.append(try? await services.download.downloadedURL(for: song))
        }
        guard !intersection.compactMap({$0}).isEmpty else {
            coordinator?.showAlert(title: "No downloads to play.", message: "You can’t enter offline mode, because you have no downloaded playlist items.")
            return
        }
        coordinator?.showPlaylist(state: PlaylistState(offlineMode: true))
    }
}

extension PingProcessor: ServerDelegate {
    /// The user has said Done after entering server info in the Server sheet.
    func userEdited(serverInfo: ServerInfo) async {
        var servers = (try? services.persistence.loadServers()) ?? []
        if let index = servers.firstIndex(where: { $0.id == serverInfo.id}) {
            servers.remove(at: index)
        }
        servers.insert(serverInfo, at: 0) // new server becomes first, i.e. default
        try? services.persistence.save(servers: servers)
        services.persistence.save(currentFolder: nil)
        services.urlMaker.currentServerInfo = serverInfo
        services.currentPlaylist.clear()
        services.cache.clear()
        await services.download.clear()
        Task {
            await cycler.receive(.doPing())
        }
    }
}
