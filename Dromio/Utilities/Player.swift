import UIKit
import AVFoundation
import MediaPlayer

@MainActor
protocol PlayerType {
    func play(url: URL, song: SubsonicSong)
}

@MainActor
final class Player: NSObject, PlayerType {
    var player = AVQueuePlayer()

    override init() {
        super.init()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget(self, action:#selector(doPlay(_:)))
        commandCenter.pauseCommand.addTarget(self, action:#selector(doPause(_:)))
        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    deinit {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.removeTarget(self)
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
    }

    func play(url: URL, song: SubsonicSong) {
        logger.log("starting to play")
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        print("playing!", url)
        try? services.audioSession.setActive(true, options: [])
        player.play()
        services.nowPlayingInfo.info = [
            .artist: song.artist,
            .title: song.title,
            .duration: song.duration ?? 0.0,
            .time: 0.0,
            .rate: 1.0
        ]
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
}
