import MediaPlayer

/// Protocol that represents the public face of our NowPlayingInfo type.
protocol NowPlayingInfoType {
    func playing(song: SubsonicSong, at: TimeInterval)
    func paused(song: SubsonicSong, at: TimeInterval)
    func clear()
}

/// Class that acts as a gateway for talking to the MPNowPlayingInfoCenter.
final class NowPlayingInfo: NowPlayingInfoType {
    /// Provider for the now playing info center to which we are the gateway.
    var centerProvider: () -> any NowPlayingInfoCenterType = { MPNowPlayingInfoCenter.default() }

    /// Dictionary that acts as a setter gateway to the now playing info center's `nowPlayingInfo` dictionary.
    var info: [NowPlayingInfoKey: NowPlayingInfoValue] {
        get { [:] } // dummy getter
        set {
            let center = centerProvider()
            var centerInfo = center.nowPlayingInfo ?? [:]
            // If song changed, remove all existing keys before setting any.
            if let id = newValue[.id], case .string(let idValue) = id {
                if (center.nowPlayingInfo?[NowPlayingInfoKey.id.value] as? String) != idValue {
                    centerInfo = [:]
                }
            }
            // set all incoming keys and values
            for (key, value) in newValue {
                centerInfo[key.value] = switch value {
                case .string(let stringValue): stringValue
                case .double(let doubleValue): doubleValue
                }
            }
            // now set the entire center now playing info
            unlessTesting {
                logger.debug("telling npi: \(centerInfo, privacy: .public)")
            }
            center.nowPlayingInfo = centerInfo
        }
    }

    /// Utility that lets us batch changes to the `info`.
    func updateInfo(_ handler: (inout [NowPlayingInfoKey: NowPlayingInfoValue]) -> () ) {
        var info = self.info
        handler(&info)
        self.info = info
    }

    /// Set our info gateway to say that the current song is playing at the given time.
    /// - Parameter time: The time (current position within the current song).
    func playing(song: SubsonicSong, at time: TimeInterval) {
        updateInfo { info in
            info[.artist] = .string(song.artist ?? "")
            info[.title] = .string(song.title)
            info[.duration] = .double(song.duration ?? 60)
            info[.id] = .string(song.id)
            info[.time] = .double(time)
            info[.rate] = .double(1.0)
        }
    }

    /// Set our info gateway to say that the current song is paused at the given time.
    /// - Parameter time: The time (current position within the current song).
    func paused(song: SubsonicSong, at time: TimeInterval) {
        updateInfo { info in
            info[.artist] = .string(song.artist ?? "")
            info[.title] = .string(song.title)
            info[.duration] = .double(song.duration ?? 60)
            info[.id] = .string(song.id)
            info[.time] = .double(time)
            info[.rate] = .double(0.0)
        }
    }

    /// Tell the now playing info center that there is no current song.
    func clear() {
        centerProvider().nowPlayingInfo = nil
        print("telling npi: clear")
    }
}

/// Struct that wraps `nowPlayingInfo` key names, to make them simpler to use.
struct NowPlayingInfoKey: Hashable {
    let value: String

    init(value: String) {
        self.value = value
    }

    static let artist = NowPlayingInfoKey(value: MPMediaItemPropertyArtist)
    static let title = NowPlayingInfoKey(value: MPMediaItemPropertyTitle)
    static let duration = NowPlayingInfoKey(value: MPMediaItemPropertyPlaybackDuration)
    static let time = NowPlayingInfoKey(value: MPNowPlayingInfoPropertyElapsedPlaybackTime)
    static let rate = NowPlayingInfoKey(value: MPNowPlayingInfoPropertyPlaybackRate)
    static let id = NowPlayingInfoKey(value: "mySecretIdentifier") // using MPNowPlayingInfoPropertyExternalContentIdentifier has bug
}

enum NowPlayingInfoValue: Equatable {
    case string(String)
    case double(Double)
}
