import Foundation
import AVFoundation
import MediaPlayer

/// Collection of mockable services used by the app. The sole instance is stored in the
/// AppDelegate as a global (crude but effective).
final class Services {
    // I don't like the singleton pattern, but it's an elegant way to ensure there can be only one.
    static var shared: Services = Services.init()
    private init() {}

    var audioSessionProvider: AudioSessionProvider = AudioSessionProvider()
    var backgroundTaskOperationMaker: BackgroundTaskOperationMakerType = BackgroundTaskOperationMaker()
    var cache: CacheType = Cache()
    var currentPlaylist: PlaylistType = Playlist()
    var download: DownloadType = Download()
    var haptic: HapticType = Haptic()
    var networker: NetworkerType = Networker()
    var nowPlayingInfo: NowPlayingInfoType = NowPlayingInfo()
    var persistence: PersistenceType = Persistence()
    var player: PlayerType = Player()
    var requestMaker: RequestMakerType = RequestMaker()
    var responseValidator: ResponseValidatorType = ResponseValidator()
    var urlMaker: URLMakerType = URLMaker()
}
