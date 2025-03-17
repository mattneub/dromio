import UIKit
import AVFoundation
import MediaPlayer
import Combine

@MainActor
protocol QueuePlayerType {
    var currentItem: AVPlayerItem? { get }
    var actionAtItemEnd: AVPlayer.ActionAtItemEnd { get set }
    func removeAllItems()
    func play()
    func pause()
    func insert(_: AVPlayerItem, after: AVPlayerItem?)
    func currentTime() -> CMTime
}

extension AVQueuePlayer: QueuePlayerType {}

@MainActor
protocol PlayerType {
    var currentItem: CurrentValueSubject<String?, Never> { get }
    func play(url: URL, song: SubsonicSong)
    func playNext(url: URL, song: SubsonicSong)
    func clear()
}

@MainActor
final class Player: NSObject, PlayerType {
    var player: QueuePlayerType = AVQueuePlayer()
    var observation: NSKeyValueObservation?

    /// Public publisher of the current item. He who has ears to hear, let him hear.
    var currentItem = CurrentValueSubject<String?, Never>(nil)

    /// List of all songs we've ever been handed, accessed by song id. Thus, if we know the id
    /// of a song, we know its title and artist. But if a song is in the queue, we have its URL.
    /// But its URL, stripped of its extension, is its id.
    var knownSongs = [String: SubsonicSong]()

    override init() {
        super.init()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget(self, action:#selector(doPlay(_:)))
        commandCenter.pauseCommand.addTarget(self, action:#selector(doPause(_:)))
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        observation = (player as? AVPlayer)?.observe(\.currentItem) { [weak self] _, _ in
            Task {
                await self?.adjustNowPlayingItemToCurrentItem()
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
            services.nowPlayingInfo.info[.artist] = song.artist
            services.nowPlayingInfo.info[.title] = song.title
            services.nowPlayingInfo.info[.duration] = song.duration
            print("current item change", song.title)
            currentItem.send(song.id)
        } else if player.currentItem == nil {
            services.nowPlayingInfo.clear()
            try? services.audioSession.setActive(false, options: [])
            currentItem.send(nil)
        }
    }

    /// Utility to extract the extension-less title of the file currently being played, which
    /// happens to be its song id.
    var currentSongId: String? {
        if let currentItem = player.currentItem, let url = (currentItem.asset as? AVURLAsset)?.url {
            return url.deletingPathExtension().lastPathComponent
        }
        return nil
    }

    func play(url: URL, song: SubsonicSong) {
        logger.log("starting to play")
        let item = AVPlayerItem(url: url)
        player.removeAllItems()
        player.insert(item, after: nil)
        print("playing!", url)
        do {
            try services.audioSession.setActive(true, options: [])
        } catch {
            print(error)
        }
        player.play()
        print("said play!")
        player.actionAtItemEnd = .advance
        // TODO: Whether because of that line or something else, if you switch from phone to
        // (say) wifi speaker route, we immediately advance to the next item in the queue
        // and the connection to the now playing info is lost; need to see what's up with that
        services.nowPlayingInfo.info = [
            .artist: song.artist,
            .title: song.title,
            .duration: song.duration ?? 0.0,
            .time: 0.0,
            .rate: 1.0
        ]
        knownSongs[song.id] = song
        currentItem.send(song.id)
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
        try? services.audioSession.setActive(true, options: [])
        player.play()
        services.nowPlayingInfo.info[.rate] = 1.0
        services.nowPlayingInfo.info[.time] = player.currentTime().seconds
        currentItem.send(currentSongId)
    }

    @objc func doPause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        logger.log("doPause")
        doPause()
        return .success
    }

    func doPause() {
        player.pause()
        // order matters
        services.nowPlayingInfo.info[.time] = player.currentTime().seconds
        services.nowPlayingInfo.info[.rate] = 0.0
    }

    func clear() {
        player.pause()
        player.removeAllItems()
        knownSongs.removeAll()
        services.nowPlayingInfo.clear()
        try? services.audioSession.setActive(false, options: [])
        currentItem.send(nil)
    }
}
