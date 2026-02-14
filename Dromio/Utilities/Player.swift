import UIKit
import AVFoundation
import MediaPlayer

/// Protocol expressing the public face of our Player class.
protocol PlayerType: Observable {
    var currentSongIdPublisher: String? { get }
    var playerStatePublisher: Player.PlayerState { get }
    func play(url: URL, song: SubsonicSong)
    func playNext(url: URL, song: SubsonicSong)
    func playPause()
    func clear()
    func backgrounding()
    func foregrounding()
}

/// Class that handles playing songs.
///
/// This is far and away the most complex single type
/// in the app; it has many kinds of work to do, because it must respond to the user
/// asking to play a sequence, asking to play / pause in the app, and asking to play / pause
/// in the remove command center, and it must update the now playing info center and manage
/// the audio session. In addition, it publishes updates on what the player is doing, so that
/// other parts of the app can subscribe and stay apprised of what is happening.
@Observable final class Player: NSObject, PlayerType, PlayerTrampolineTargetType {
    /// The _real_ player. Set in the initializer.
    let player: any QueuePlayerType

    /// Function that obtains a reference to the remote command center. In this way we can be
    /// handed this function on initialization by the app or (with a mock) by the tests,
    /// without keeping a reference to the command center itself.
    let commandCenterProvider: (@Sendable () -> any RemoteCommandCenterType)

    /// Trampoline object that acts as the target of all MPRemoteCommandEvent actions.
    /// Set in the initializer.
    let trampoline: any PlayerTrampolineType

    /// Observation of the queue player's current item, so we are notified when it changes.
    private var queuePlayerCurrentItemObservation: NSKeyValueObservation?

    /// Observation of the queue player's rate, so we are notified when it changes. We need this
    /// for the edge case where the user removes an earphones route while we are playing. The
    /// docs specifically call this out: "To observe this player behavior," [i.e. the user disconnects headphones],
    /// "key-value observe the player’s rate property so that you can update your user interface
    /// as the player pauses playback.
    private var queuePlayerRateObservation: NSKeyValueObservation?

    /// Observation of the audio session interruption notification, so we are notified when interruption
    /// starts or ends.
    private var interruptionObservation: (any NSObjectProtocol)?

    /// Observation of the player periodically while it has items. We are currently not using this,
    /// and with luck we will not have to use it.
    private var periodicObservation: Any?

    /// Public publisher of the current item. Who has ears to hear, let him hear.
    var currentSongIdPublisher: String?

    /// Public publisher of the current player state. Who has ears to hear, let him hear.
    var playerStatePublisher: PlayerState = .empty

    /// List of all songs we've ever been handed, accessed by song id. Thus, if we know the id
    /// of a song, we know its title and artist. Well, if a song is in the queue, we have its URL —
    /// and its URL, stripped of its extension, is its id. See `currentSongId`, below.
    var knownSongs = [String: SubsonicSong]()

    /// Initializer.
    /// - Parameters:
    ///   - player: A queue player, wrapped in a protocol for testing. By default, this will be
    ///     an AVQueuePlayer, and the app should not override this; only a test should use this parameter.
    ///   - commandCenterProvider: A function that provides a reference to the command center, wrapped in a
    ///     protocol for testing. By default, this function return the shared remote command center, and
    ///     the app should not override this; only a test should use this parameter.
    init(
        player: any QueuePlayerType = AVQueuePlayer(),
        commandCenterProvider: @Sendable @escaping () -> any RemoteCommandCenterType = { MPRemoteCommandCenter.shared() },
        trampoline: any PlayerTrampolineType = PlayerTrampoline()
    ) {
        self.player = player
        self.commandCenterProvider = commandCenterProvider
        self.trampoline = trampoline
        super.init()
        // finishing configuring the trampoline
        trampoline.player = self
        // configure the command center
        let commandCenter = self.commandCenterProvider()
        commandCenter.play.addTarget(trampoline, action: #selector(PlayerTrampoline.doPlay(_:)))
        commandCenter.pause.addTarget(trampoline, action: #selector(PlayerTrampoline.doPause(_:)))
        commandCenter.skipBack.addTarget(trampoline, action: #selector(PlayerTrampoline.doSkipBack(_:)))
        commandCenter.skipBack.setInterval(30)
        commandCenter.skipForward.addTarget(trampoline, action: #selector(PlayerTrampoline.doSkipForward(_:)))
        commandCenter.skipForward.setInterval(30)
        commandCenter.changePlaybackPosition.isEnabled = false
        // prepare our various observations
        queuePlayerCurrentItemObservation = (player as? AVPlayer)?.observe(\.currentItem, options: [.new]) { [weak self] _, item in
            Task {
                await logger.debug("current item change: \(String(describing: item.newValue), privacy: .public)")
                await self?.adjustNowPlayingItemToCurrentItem()
            }
        }
        queuePlayerRateObservation = (player as? AVPlayer)?.observe(\.rate, options: [.new]) { [weak self] _, item in
            Task {
                await logger.debug("rate change: \(String(describing: item.newValue), privacy: .public)")
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
                        logger.debug("interruption started")
                    }
                case .ended:
                    unlessTesting {
                        logger.debug("interruption ended")
                    }
                    if self?.player.rate == 0 {
                        // "prime the pump" by activating session, signalling info center
                        logger.debug("priming the pump")
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
        Task { @MainActor [commandCenterProvider] in // capture is crucial
            let commandCenter = commandCenterProvider()
            commandCenter.play.removeTarget(nil) // remove all
            commandCenter.pause.removeTarget(nil) // remove all
            commandCenter.skipForward.removeTarget(nil) // remove all
            commandCenter.skipBack.removeTarget(nil) // remove all
        }
    }

    /// Called by observations, when the player's current item or rate changes.
    private func adjustNowPlayingItemToCurrentItem() {
        if currentSong != nil {
            doPlay(updateOnly: true)
        } else if player.currentItem == nil && player.rate == 1 { // reached end of queue
            clear()
        }
        currentSongIdPublisher = currentSongId
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
        removePeriodicObservation()
        player.pause()
        services.nowPlayingInfo.clear()
        player.removeAllItems()
        player.insert(AVPlayerItem(url: url), after: nil)
        player.actionAtItemEnd = .advance
        logger.debug("playing! \(url, privacy: .public)")
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

    /// Major workhorse. Assert our session; if we are not actually playing, play; update now
    /// playing info; and update our current song publisher.
    /// - Parameter updateOnly: Flag. If true, do all the updating, but don't actually play.
    ///   If false, the caller means _really_ play.
    func doPlay(updateOnly: Bool) {
        unlessTesting {
            logger.debug("activating session")
        }
        try? services.audioSessionProvider.provide().setActive(true, options: [])
        if player.rate == 0 && !updateOnly {
            logger.debug("telling player to play")
            player.play()
            configurePeriodicObservation()
        }
        if let song = currentSong {
            if player.rate == 0 {
                services.nowPlayingInfo.paused(song: song, at: player.currentTime().seconds)
                playerStatePublisher = .paused
            } else {
                services.nowPlayingInfo.playing(song: song, at: player.currentTime().seconds)
                playerStatePublisher = .playing
            }
        }
        currentSongIdPublisher = currentSongId
    }

    /// Implementation of both `doSkipBack` and `doSkipForward`, i.e. combined response
    /// to remote command center saying `skipBack` or `skipForward`. The response differs
    /// only by a plus or minus sign, adding or subtracting the specified skip interval.
    func skip(forward: Bool, event: any RemoteCommandEventType) -> MPRemoteCommandHandlerStatus {
        guard player.rate != 0 else {
            return .commandFailed
        }
        // this dance to obtain `event.interval` is not really needed, as it will always be 30
        guard let event = event as? any SkipIntervalCommandEventType else {
            return .commandFailed
        }
        let interval = event.interval * (forward ? 1 : -1)
        let targetTime = player.currentTime() + CMTime(seconds: interval, preferredTimescale: 1)
        Task { @MainActor in
            if await player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) {
                self.doPlay(updateOnly: true)
            }
        }
        return .success
    }

    /// Pause the queue player. If playing, this will trigger a rate change which will call `doPlay` to update everything.
    func doPause() {
        player.pause()
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
            logger.debug("deactivating session")
        }
        try? services.audioSessionProvider.provide().setActive(false, options: [])
        currentSongIdPublisher = nil
        playerStatePublisher = .empty
    }

    /// We are advised to deactivate on backgrounding if not actively playing, to avoid
    /// a confusing extra "interruption" notification later. So this method is called from
    /// the scene delegate, and we do exactly that.
    func backgrounding() {
        if player.rate == 0 {
            unlessTesting {
                logger.debug("deactivating session")
            }
            try? services.audioSessionProvider.provide().setActive(false, options: [])
        }
    }

    /// Called by the scene delegate. Just to be on the safe side, update all our info when we
    /// return from the background, _if we are already playing._ If we are not already playing,
    /// do nothing, because we don't want to grab the now playing info center and audio session
    /// away from someone else who may have it. If the user wants to resume playing, that's what
    /// the playpause button is for.
    func foregrounding() {
        try? services.audioSessionProvider.provide().setCategory(.playback, mode: .default, options: [])
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
