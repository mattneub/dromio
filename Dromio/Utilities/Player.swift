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
}

extension AVQueuePlayer: QueuePlayerType {}

@MainActor
protocol PlayerType {
    var currentSongIdPublisher: CurrentValueSubject<String?, Never> { get }
    func play(url: URL, song: SubsonicSong)
    func playNext(url: URL, song: SubsonicSong)
    func clear()
    func backgrounding()
    func foregrounding()
}

@MainActor
final class Player: NSObject, PlayerType {
    /// The _real_ player.
    let player: any QueuePlayerType

    /// Observation of the queue player's current item, so we are notified when it changes.
    var queuePlayerCurrentItemObservation: NSKeyValueObservation?

    /// Public publisher of the current item. He who has ears to hear, let him hear.
    var currentSongIdPublisher = CurrentValueSubject<String?, Never>(nil)

    /// List of all songs we've ever been handed, accessed by song id. Thus, if we know the id
    /// of a song, we know its title and artist. But if a song is in the queue, we have its URL.
    /// But its URL, stripped of its extension, is its id.
    var knownSongs = [String: SubsonicSong]()

    /// Observation of the audio session interruption notification, so we are notified when interruption
    /// starts or ends.
    var interruptionObservation: (any NSObjectProtocol)?

    init(player: any QueuePlayerType) {
        self.player = player
        super.init()
        // configure the command center
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget(self, action: #selector(doPlay(_:)))
        commandCenter.pauseCommand.addTarget(self, action: #selector(doPause(_:)))
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        // prepare our various observations
        queuePlayerCurrentItemObservation = (player as? AVPlayer)?.observe(\.currentItem, options: [.new]) { [weak self] _, item in
            Task {
                logger.log("current item change: \(String(describing: item.newValue), privacy: .public)")
                await self?.adjustNowPlayingItemToCurrentItem()
            }
        }
        interruptionObservation = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
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
                    self?.primeThePump()
                case .none: break
                case .some(_): break
                }
            }
        }
    }

    deinit {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.removeTarget(self)
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
    }

    func adjustNowPlayingItemToCurrentItem() {
        if let id = currentSongId, let song = knownSongs[id] {
            services.nowPlayingInfo.display(song: song)
        } else if player.currentItem == nil {
            services.nowPlayingInfo.clear()
            unlessTesting {
                logger.log("deactivating session")
            }
            try? services.audioSession.setActive(false, options: [])
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

    func play(url: URL, song: SubsonicSong) {
        logger.log("starting to play")
        let item = AVPlayerItem(url: url)
        player.removeAllItems()
        player.insert(item, after: nil)
        unlessTesting {
            logger.log("activating session")
        }
        try? services.audioSession.setActive(true, options: [])
        logger.log("playing! \(url, privacy: .public)")
        player.play()
        player.actionAtItemEnd = .advance
        services.nowPlayingInfo.display(song: song)
        services.nowPlayingInfo.playingAt(0)
        knownSongs[song.id] = song
        currentSongIdPublisher.send(song.id)
    }

    func playNext(url: URL, song: SubsonicSong) {
        let item = AVPlayerItem(url: url)
        player.insert(item, after: nil) // "nil" means "at the end" (oddly enough)
        knownSongs[song.id] = song
    }

    @objc func doPlay(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        logger.log("doPlay")
        doPlay()
        return .success
    }

    func doPlay() {
        unlessTesting {
            logger.log("activating session")
        }
        try? services.audioSession.setActive(true, options: [])
        player.play()
        services.nowPlayingInfo.playingAt(player.currentTime().seconds)
        currentSongIdPublisher.send(currentSongId)
    }

    @objc func doPause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        logger.log("doPause")
        doPause()
        return .success
    }

    func doPause() {
        player.pause()
        services.nowPlayingInfo.pausedAt(player.currentTime().seconds)
    }

    // TODO: The big question is: do I need to "write down" the current item info outside of the queue player?
    // And I think the answer is: not as long as I reassert the now playing item any time we foreground;
    // but if I don't want to do that, then the app needs a "resume" button at least

    func primeThePump() {
        if player.rate == 0, let id = currentSongId, let song = knownSongs[id] { // i.e. we are _paused_
            services.nowPlayingInfo.display(song: song)
            // these calls will activate the session, set the `nowPlayingInfo` time to the player's current time,
            // and make sure we do in fact take over the now playing info center
            doPlay()
            doPause()
        }
    }

    func clear() {
        player.pause()
        player.removeAllItems()
        knownSongs.removeAll()
        services.nowPlayingInfo.clear()
        unlessTesting {
            logger.log("deactivating session")
        }
        try? services.audioSession.setActive(false, options: [])
        currentSongIdPublisher.send(nil)
    }

    func backgrounding() {
        // we are advised to deactivate on backgrounding if not actively playing, to avoid
        // a confusing extra "interruption" notification later
        if player.rate == 0 {
            unlessTesting {
                logger.log("deactivating session")
            }
            try? services.audioSession.setActive(false, options: [])
        }
    }

    func foregrounding() {
        primeThePump()
    }
}
