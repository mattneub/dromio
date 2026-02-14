import Foundation

/// Protocol expressing the public face of our Persistence struct.
protocol PersistenceType {
    func saveCurrentPlaylist(songList: [SubsonicSong]) throws
    func loadCurrentPlaylist() throws -> [SubsonicSong]
    func save(servers: [ServerInfo]) throws
    func loadServers() throws -> [ServerInfo]
    func save(currentFolder: SubsonicFolder?, suppressName: Bool)
    func loadCurrentFolder() -> Int?
    func loadCurrentFolderName() -> String?
}
extension PersistenceType {
    func save(currentFolder: SubsonicFolder?) {
        save(currentFolder: currentFolder, suppressName: false)
    }
}

/// Struct that implements persistence. There are two kinds; we can save something into
/// UserDefaults, or we can save something into the keychain. In reality we save only two
/// things: the current playlist, and the list of servers. When we save/fetch a server,
/// its password is replaced by a dummy and the real password lives in the keychain.
struct Persistence: PersistenceType {
    static var defaults: any UserDefaultsType = UserDefaults.standard
    static var keychain: any KeychainType = Keychain.shared

    /// Save the current playlist's songs into user defaults.
    /// - Parameter songList: Array of songs.
    func saveCurrentPlaylist(songList: [SubsonicSong]) throws {
        Self.defaults.set(try songList.map { song in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            unlessTesting {
                encoder.outputFormatting = []
            }
            let data = try encoder.encode(song)
            return String(data: data, encoding: .utf8)
        }, forKey: PersistenceKey.currentPlaylist.rawValue)
    }

    /// Fetch the current playlist songs from user defaults.
    /// - Returns: The list of songs.
    func loadCurrentPlaylist() throws -> [SubsonicSong] {
        let list = Self.defaults.stringArray(forKey: PersistenceKey.currentPlaylist.rawValue) ?? []
        return try list.map { song in
            let data = song.data(using: .utf8) ?? Data()
            return try JSONDecoder().decode(SubsonicSong.self, from: data)
        }
    }

    /// Save the list of servers into user defaults, with the passwords going into the keychain.
    /// - Parameter servers: The list of servers.
    func save(servers: [ServerInfo]) throws {
        Self.defaults.set(try servers.map { server in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            unlessTesting {
                encoder.outputFormatting = []
            }
            let data = try encoder.encode(server.updateWithoutPassword())
            return String(data: data, encoding: .utf8)
        }, forKey: PersistenceKey.servers.rawValue)
        for server in servers {
            Self.keychain[server.id] = server.password
        }
    }

    /// Fetch the list of servers from user defaults, with the passwords coming from the keychain.
    /// - Returns: The list of servers.
    func loadServers() throws -> [ServerInfo] {
        let list = Self.defaults.stringArray(forKey: PersistenceKey.servers.rawValue) ?? []
        let servers = try list.map { server in
            let data = server.data(using: .utf8) ?? Data()
            return try JSONDecoder().decode(ServerInfo.self, from: data)
        }.map { server in
            let newPassword = Self.keychain[server.id] ?? ""
            return server.updateWithPassword(newPassword)
        }
        return servers
    }

    /// Save info about the current folder. We save the id and name separately, because those
    /// two pieces of info have different clients interested in them.
    /// - Parameters:
    ///   - currentFolder: The folder.
    ///   - suppressName: If true, save nil as the name even though the folder has one. This is
    ///   because if there is only one folder for this user, we do not want to show the name.
    func save(currentFolder: SubsonicFolder?, suppressName: Bool) {
        Self.defaults.set(currentFolder?.id, forKey: PersistenceKey.currentFolder.rawValue)
        if suppressName {
            Self.defaults.set(nil, forKey: PersistenceKey.currentFolderName.rawValue)
        } else {
            Self.defaults.set(currentFolder?.name, forKey: PersistenceKey.currentFolderName.rawValue)
        }
    }

    /// Fetch the current folder id, if any.
    func loadCurrentFolder() -> Int? {
        Self.defaults.object(forKey: PersistenceKey.currentFolder.rawValue) as? Int
    }

    /// Fetch the current folder name, if any.
    func loadCurrentFolderName() -> String? {
        Self.defaults.object(forKey: PersistenceKey.currentFolderName.rawValue) as? String
    }
}

/// Keys for saving/fetching into/from UserDefaults.
enum PersistenceKey: String {
    case currentFolder
    case currentFolderName
    case currentPlaylist
    case servers
}
