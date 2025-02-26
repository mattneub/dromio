import Foundation
import AVFoundation

/// Collection of mockable services used by the app. The sole instance is stored in the
/// AppDelegate as a global (crude but effective).
@MainActor
struct Services {
    var audioSession: AudioSessionType = AVAudioSession.sharedInstance()
    var currentPlaylist: PlaylistType = Playlist()
    var download: DownloadType = Download()
    var haptic: HapticType = Haptic()
    var networker: NetworkerType = Networker()
    var nowPlayingInfo: NowPlayingInfoType = NowPlayingInfo()
    var player: PlayerType = Player()
    var requestMaker: RequestMakerType = RequestMaker()
    var responseValidator: ResponseValidatorType = ResponseValidator()
    var urlMaker: URLMakerType = URLMaker()
}
