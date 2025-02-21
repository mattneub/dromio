import Foundation

/// Collection of mockable services used by the app. The sole instance is stored in the
/// AppDelegate as a global (crude but effective).
@MainActor
struct Services {
    var networker: NetworkerType = Networker()
    var requestMaker: RequestMakerType = RequestMaker()
    var responseValidator: ResponseValidatorType = ResponseValidator()
    var urlMaker: URLMakerType = URLMaker()
}
