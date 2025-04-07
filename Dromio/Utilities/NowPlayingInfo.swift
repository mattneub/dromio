import MediaPlayer

/// Protocol that represents the public face of our NowPlayingInfo type.
protocol NowPlayingInfoType {
    func display(song: SubsonicSong)
    func playingAt(_: TimeInterval)
    func pausedAt(_: TimeInterval)
    func clear()
}

/// Class that acts as a gateway for talking to the MPNowPlayingInfoCenter.
final class NowPlayingInfo: NowPlayingInfoType {
    /// Reference to the now playing info center to which we are the gateway.
    var center: NowPlayingInfoCenterType = MPNowPlayingInfoCenter.default()

    /// Dictionary that acts as a gateway to the now playing info center's `nowPlayingInfo` dictionary.
    /// Should be private, but we have to make it public for testing purposes.
    var info: [NowPlayingInfoKey: Any] = [:] {
        didSet {
            var centerInfo = center.nowPlayingInfo ?? [:]
            for (key, value) in info {
                centerInfo[key.value] = value
            }
            center.nowPlayingInfo = centerInfo
        }
    }

    /// Utility that batches changes to our `info` gateway, so we can set multiple keys
    /// but set the `info` just once.
    private func withInfo(_ handler: (inout [NowPlayingInfoKey: Any]) -> ()) {
        var info = self.info
        handler(&info)
        self.info = info
    }

    /// Given a song, set our info gateway for display of its metadata.
    /// - Parameter song: The song.
    func display(song: SubsonicSong) {
        withInfo { info in
            info[.artist] = song.artist
            info[.title] = song.title
            info[.duration] = song.duration ?? 60
        }
    }

    /// Set our info gateway to say that the current song is playing at the given time.
    /// - Parameter time: The time (current position within the current song).
    func playingAt(_ time: TimeInterval) {
        withInfo { info in
            info[.time] = time
            info[.rate] = 1.0
        }
    }
    /// Set our info gateway to say that the current song is paused at the given time.
    /// - Parameter time: The time (current position within the current song).
    func pausedAt(_ time: TimeInterval) {
        withInfo { info in
            info[.time] = time
            info[.rate] = 0.0
        }
    }

    /// Tell the now playing info center that there is no current song.
    func clear() {
        center.nowPlayingInfo = nil
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
}
