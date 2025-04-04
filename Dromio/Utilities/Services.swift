import Foundation
import AVFoundation
import MediaPlayer

/// Collection of mockable services used by the app. The sole instance is stored in the
/// AppDelegate as a global (crude but effective).
@MainActor
struct Services {
    var audioSession: AudioSessionType = AVAudioSession.sharedInstance()
    var backgroundTaskOperationMaker: BackgroundTaskOperationMakerType = BackgroundTaskOperationMaker()
    var currentPlaylist: PlaylistType = Playlist()
    var download: DownloadType = Download()
    var haptic: HapticType = Haptic()
    var networker: NetworkerType = Networker()
    var nowPlayingInfo: NowPlayingInfoType = NowPlayingInfo()
    var persistence: PersistenceType = Persistence()
    var player: PlayerType = Player(player: AVQueuePlayer(), commandCenterMaker: { MPRemoteCommandCenter.shared() })
    var requestMaker: RequestMakerType = RequestMaker()
    var responseValidator: ResponseValidatorType = ResponseValidator()
    var urlMaker: URLMakerType = URLMaker()
}
