import Foundation

enum PersistenceKey: String {
    case currentPlaylist
    case servers
}

@MainActor
protocol UserDefaultsType {
    func stringArray(forKey: String) -> [String]?
    func set(_ value: Any?, forKey: String )
}

extension UserDefaults: UserDefaultsType {}

protocol KeychainType {
    subscript(key: String) -> String? { get set }
}

extension Keychain: KeychainType {}

@MainActor
protocol PersistenceType {
    func save(songList: [SubsonicSong], key: PersistenceKey) throws
    func loadSongList(key: PersistenceKey) throws -> [SubsonicSong]
    func save(servers: [ServerInfo]) throws
    func loadServers() throws -> [ServerInfo]
}

@MainActor
struct Persistence: PersistenceType {
    static var defaults: UserDefaultsType = UserDefaults.standard
    static var keychain: KeychainType = Keychain.shared

    func save(songList: [SubsonicSong], key: PersistenceKey) throws {
        Self.defaults.set(try songList.map { song in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            unlessTesting {
                encoder.outputFormatting = []
            }
            let data = try encoder.encode(song)
            return String(data: data, encoding: .utf8)
        }, forKey: key.rawValue)
    }

    func loadSongList(key: PersistenceKey) throws -> [SubsonicSong] {
        let list = Self.defaults.stringArray(forKey: key.rawValue) ?? []
        return try list.map { song in
            let data = song.data(using: .utf8) ?? Data()
            return try JSONDecoder().decode(SubsonicSong.self, from: data)
        }
    }

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
}
