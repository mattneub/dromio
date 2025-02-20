import Foundation

@MainActor
struct Services {
    var networker: NetworkerType = Networker()
    var requestMaker: RequestMakerType = RequestMaker()
    var responseValidator: ResponseValidatorType = ResponseValidator()
    var urlMaker: URLMakerType = URLMaker()
}
