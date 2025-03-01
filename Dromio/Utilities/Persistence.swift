import Foundation

enum PersistenceKey: String {
    case currentPlaylist
}

@MainActor
protocol UserDefaultsType {
    func stringArray(forKey: String) -> [String]?
    func set(_ value: Any?, forKey: String )
}

extension UserDefaults: UserDefaultsType {}

@MainActor
protocol PersistenceType {
    func save(songList: [SubsonicSong], key: PersistenceKey) throws
    func loadSongList(key: PersistenceKey) throws -> [SubsonicSong]
}

@MainActor
struct Persistence: PersistenceType {
    static var defaults: UserDefaultsType = UserDefaults.standard

    func save(songList: [SubsonicSong], key: PersistenceKey) throws {
        Self.defaults.set(try songList.map { song in
            let encoder = JSONEncoder()
            if NSClassFromString("XCTest") != nil {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
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
}
