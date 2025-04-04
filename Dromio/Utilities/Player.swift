import UIKit
import AVFoundation
import MediaPlayer
import Combine

@MainActor
protocol QueuePlayerType: AnyObject {
    var currentItem: AVPlayerItem? { get }
    var actionAtItemEnd: AVPlayer.ActionAtItemEnd { get set }
    func removeAllItems()
    func play()
    func pause()
    func insert(_: AVPlayerItem, after: AVPlayerItem?)
    func currentTime() -> CMTime
    var rate: Float { get set }
    func addPeriodicTimeObserver(
        forInterval interval: CMTime,
        queue: dispatch_queue_t?,
        using block: @escaping @Sendable (CMTime) -> Void
    ) -> Any
    func removeTimeObserver(_ observer: Any)
}

extension AVQueuePlayer: QueuePlayerType {}

@MainActor
protocol PlayerType {
    var currentSongIdPublisher: CurrentValueSubject<String?, Never> { get }
    var playerStatePublisher: CurrentValueSubject<Player.PlayerState, Never> { get }
    func play(url: URL, song: SubsonicSong)
    func playNext(url: URL, song: SubsonicSong)
    func playPause()
    func clear()
    func backgrounding()
    func foregrounding()
}

@MainActor
final class Player: NSObject, PlayerType {
    /// The _real_ player.
    let player: any QueuePlayerType

    /// Function that obtains a reference to the remote command center. In this way we can be
    /// handed this function on initialization by the app or (with a mock) by the tests,
    /// without keeping a reference to the command center itself.
    var commandCenterMaker: (@Sendable () -> any RemoteCommandCenterType)?

    /// Observation of the queue player's current item, so we are notified when it changes.
    var queuePlayerCurrentItemObservation: NSKeyValueObservation?

    /// Observation of the queue player's rate, so we are notified when it changes. We need this
    /// for the edge case where the user removes an earphones route while we are playing. The
    /// docs specifically call this out: "To observe this player behavior," [i.e. the user disconnects headphones],
    /// "key-value observe the player’s rate property so that you can update your user interface
    /// as the player pauses playback.
    var queuePlayerRateObservation: NSKeyValueObservation?

    /// Public publisher of the current item. He who has ears to hear, let him hear.
    var currentSongIdPublisher = CurrentValueSubject<String?, Never>(nil)

    /// Public publisher of the current player state.
    var playerStatePublisher = CurrentValueSubject<PlayerState, Never>(.empty)

    /// List of all songs we've ever been handed, accessed by song id. Thus, if we know the id
    /// of a song, we know its title and artist. But if a song is in the queue, we have its URL.
    /// But its URL, stripped of its extension, is its id.
    var knownSongs = [String: SubsonicSong]()

    /// Observation of the audio session interruption notification, so we are notified when interruption
    /// starts or ends.
    var interruptionObservation: (any NSObjectProtocol)?

    /// Observation of the player periodically while it has items.
    var periodicObservation: Any?

    init(player: any QueuePlayerType, commandCenterMaker: @Sendable @escaping () -> any RemoteCommandCenterType) {
        self.player = player
        self.commandCenterMaker = commandCenterMaker
        super.init()
        // configure the command center
        let commandCenter = self.commandCenterMaker?()
        commandCenter?.play.addTarget(self, action: #selector(doPlay(_:)))
        commandCenter?.pause.addTarget(self, action: #selector(doPause(_:)))
        commandCenter?.changePlaybackPosition.isEnabled = false
        // prepare our various observations
        queuePlayerCurrentItemObservation = (player as? AVPlayer)?.observe(\.currentItem, options: [.new]) { [weak self] _, item in
            Task {
                logger.log("current item change: \(String(describing: item.newValue), privacy: .public)")
                await self?.adjustNowPlayingItemToCurrentItem()
            }
        }
        queuePlayerRateObservation = (player as? AVPlayer)?.observe(\.rate, options: [.new]) { [weak self] _, item in
            Task {
                logger.log("rate change: \(String(describing: item.newValue), privacy: .public)")
                await self?.adjustNowPlayingItemToCurrentItem()
            }
        }
        interruptionObservation = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            var type: AVAudioSession.InterruptionType?
            if let info = notification.userInfo {
                if let interruptionType = info[AVAudioSessionInterruptionTypeKey] as? UInt {
                    type = .init(rawValue: interruptionType)
                }
            }
            MainActor.assumeIsolated { // safe because I did say `.main` a moment ago
                switch type {
                case .began:
                    unlessTesting {
                        logger.log("interruption started")
                    }
                case .ended:
                    unlessTesting {
                        logger.log("interruption ended")
                    }
                    if self?.player.rate == 0 {
                        // "prime the pump" by activating session, signalling info center
                        self?.doPlay(updateOnly: false)
                        self?.doPause()
                    }
                case .none: break
                case .some(_): break
                }
            }
        }
    }

    deinit {
        let commandCenter = commandCenterMaker?()
        commandCenter?.play.removeTarget(self)
        commandCenter?.pause.removeTarget(self)
    }

    /// Called when the player's current item changes.
    func adjustNowPlayingItemToCurrentItem() {
        if currentSong != nil {
            doPlay(updateOnly: true)
        } else if player.currentItem == nil {
            removePeriodicObservation()
            services.nowPlayingInfo.clear()
            unlessTesting {
                logger.log("deactivating session")
            }
            try? services.audioSession.setActive(false, options: [])
            playerStatePublisher.send(.empty)
        }
        currentSongIdPublisher.send(currentSongId)
    }

    /// Utility to obtain the song id of player's current item, based on its URL.
    var currentSongId: String? {
        if let currentItem = player.currentItem, let url = (currentItem.asset as? AVURLAsset)?.url {
            // well, it depends if we're playing by streaming or from a download, doesn't it?
            if url.scheme == "file" {
                return url.deletingPathExtension().lastPathComponent
            } else if url.scheme == "http" || url.scheme == "https" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    if let queries = components.queryItems {
                        if let idItem = queries.first(where: { $0.name == "id" }) {
                            return idItem.value
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Utility to obtain the current song, based on the current song id and the known songs.
    var currentSong: SubsonicSong? {
        if let id = currentSongId, let song = knownSongs[id] {
            return song
        }
        return nil
    }

    /// Stop playing, remove the existing queue, and create a new queue starting with the resource
    /// at the given URL, and start playing.
    /// - Parameters:
    ///   - url: URL of the resource. May be local (file) or remote (http(s)).
    ///   - song: SubsonicSong info associated with this URL.
    func play(url: URL, song: SubsonicSong) {
        logger.log("starting to play")
        removePeriodicObservation()
        player.removeAllItems()
        player.insert(AVPlayerItem(url: url), after: nil)
        unlessTesting {
            logger.log("activating session")
        }
        logger.log("playing! \(url, privacy: .public)")
        knownSongs[song.id] = song // order matters
        doPlay(updateOnly: false)
    }

    /// Without pausing (or playing), queue the resource at the given URL at the end of the
    /// current queue.
    /// - Parameters:
    ///   - url: URL of the resource. May be local (file) or remote (http(s)).
    ///   - song: SubsonicSong info associated with this URL.
    func playNext(url: URL, song: SubsonicSong) {
        player.insert(AVPlayerItem(url: url), after: nil) // "nil" means "at the end" (oddly enough)
        knownSongs[song.id] = song
    }

    /// Response to the remote command center saying "play".
    @objc func doPlay(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        logger.log("doPlay")
        doPlay(updateOnly: false)
        return .success
    }

    /// Major workhorse. Assert our session; if we are not actually playing, play; update now
    /// playing info; and update our current song publisher.
    /// - Parameter updateOnly: Flag. If true, do all the updating, but don't actually play.
    ///   If false, the caller means _really_ play.
    func doPlay(updateOnly: Bool) {
        unlessTesting {
            logger.log("activating session")
        }
        try? services.audioSession.setActive(true, options: [])
        if player.rate == 0 && !updateOnly {
            player.play()
            configurePeriodicObservation()
        }
        if let song = currentSong {
            services.nowPlayingInfo.display(song: song)
        }
        if player.rate == 0 {
            services.nowPlayingInfo.pausedAt(player.currentTime().seconds)
            playerStatePublisher.send(.paused)
        } else {
            services.nowPlayingInfo.playingAt(player.currentTime().seconds)
            playerStatePublisher.send(.playing)
        }
        currentSongIdPublisher.send(currentSongId)
    }

    /// Response to the remote command center saying "pause".
    @objc func doPause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        logger.log("doPause")
        doPause()
        return .success
    }

    /// Minor workhorse. Pause the queue player and update the now playing info center.
    func doPause() {
        try? services.audioSession.setActive(true, options: [])
        player.pause()
        services.nowPlayingInfo.pausedAt(player.currentTime().seconds)
        playerStatePublisher.send(.paused)
    }

    /// Public toggle, used by the playpause button in the playlist interface.
    func playPause() {
        if player.rate > 0 {
            doPause()
        } else {
            doPlay(updateOnly: false)
        }
    }

    /// Tear down everything: stop playing and empty the queue, throw away the known songs,
    /// remove our info from the now playing info center, deactivate the session, notify that
    /// there is now no current song.
    func clear() {
        removePeriodicObservation()
        player.pause()
        player.removeAllItems()
        knownSongs.removeAll()
        services.nowPlayingInfo.clear()
        unlessTesting {
            logger.log("deactivating session")
        }
        try? services.audioSession.setActive(false, options: [])
        currentSongIdPublisher.send(nil)
        playerStatePublisher.send(.empty)
    }

    /// We are advised to deactivate on backgrounding if not actively playing, to avoid
    /// a confusing extra "interruption" notification later. So this method is called from
    /// the scene delegate, and we do exactly that.
    func backgrounding() {
        if player.rate == 0 {
            unlessTesting {
                logger.log("deactivating session")
            }
            try? services.audioSession.setActive(false, options: [])
        }
    }

    /// Called by the scene delegate. Just to be on the safe side, update all our info when we
    /// return from the background, _if we are already playing._ If we are not already playing,
    /// do nothing, because we don't want to grab the now playing info center and audio session
    /// away from someone else who may have it. If the user wants to resume playing, that's what
    /// the playpause button is for.
    func foregrounding() {
        if player.rate > 0 {
            doPlay(updateOnly: true)
        }
    }

    /// Enum describing the state of the player.
    enum PlayerState: Equatable {
        case empty
        case playing
        case paused
    }
}

/*
 I would really rather not have to do frequent periodic checking and updating, but occasionally
 the now playing info just goes bonkers, so it seems like it might be necessary. Just in case,
 I am sequestering them in this extension and putting them behind a sort of feature flag.
 */
extension Player {
    static var usePeriodicObservation = false

    func configurePeriodicObservation() {
        guard Self.usePeriodicObservation else {
            return
        }
        guard periodicObservation == nil else {
            return
        }
        periodicObservation = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 2),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                self?.doPlay(updateOnly: true)
            }
        }
    }

    func removePeriodicObservation() {
        guard Self.usePeriodicObservation else {
            return
        }
        guard let periodicObservation else {
            return
        }
        player.removeTimeObserver(periodicObservation)
        self.periodicObservation = nil
    }
}
