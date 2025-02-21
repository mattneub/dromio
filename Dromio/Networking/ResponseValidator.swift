import Foundation

/// Protocol expressing the public face of the ResponseValidator.
@MainActor
protocol ResponseValidatorType {
    func validateResponse<T: InnerResponse>(_ jsonResponse: SubsonicResponse<T>) async throws
}

/// A SubsonicResponse wrapping an InnerResponse arrives with a bunch of properties that tell us
/// we're talking to the right kind of server and our request was ok. This struct factors out
/// validation of these properties. After decoding the response, it should be passed to this
/// validator for final checking — and that is what RequestMaker does.
///
@MainActor
struct ResponseValidator: ResponseValidatorType {

    /// Given a decoded SubsonicResponse wrapping an InnerResponse, validate the properties of the
    /// InnerResponse. Throws if all is not well.
    ///
    func validateResponse<T: InnerResponse>(_ jsonResponse: SubsonicResponse<T>) async throws {
        guard jsonResponse.subsonicResponse.type == "navidrome" else {
            throw NetworkerError.message("The server does not appear to be a Navidrome server.")
        }
        // TODO: Should check the serverVersion too, eventually
        guard jsonResponse.subsonicResponse.status == "ok" else {
            if let subsonicError = jsonResponse.subsonicResponse.error {
                throw NetworkerError.message(subsonicError.message)
            } else {
                throw NetworkerError.message("We got a failed status from the Navidrome server.")
            }
        }
    }
}
