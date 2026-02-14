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
    var backgroundTaskOperationMaker: any BackgroundTaskOperationMakerType = BackgroundTaskOperationMaker()
    var cache: any CacheType = Cache()
    var currentPlaylist: any PlaylistType = Playlist()
    var download: any DownloadType = Download()
    var haptic: any HapticType = Haptic()
    var networker: any NetworkerType = Networker()
    var nowPlayingInfo: any NowPlayingInfoType = NowPlayingInfo()
    var persistence: any PersistenceType = Persistence()
    var player: any PlayerType = Player()
    var requestMaker: any RequestMakerType = RequestMaker()
    var responseValidator: any ResponseValidatorType = ResponseValidator()
    var urlMaker: any URLMakerType = URLMaker()
}
