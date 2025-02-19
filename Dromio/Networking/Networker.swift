import Foundation

enum NetworkerError: Error, Equatable {
    case message(String)
}

@MainActor protocol NetworkerType {
    func ping() async throws
}

@MainActor
final class Networker: NetworkerType {
    let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: config)
            self.session = session
        }
    }

    func ping() async throws {
        guard let url = URLMaker.urlFor(action: "ping") else {
            throw NetworkerError.message("We created a malformed URL.")
        }
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw NetworkerError.message("We received a non-HTTPURLResponse.")
        }
        guard statusCode == 200 else {
            throw NetworkerError.message("We got a status code \(statusCode).")
        }
        let jsonResponse = try JSONDecoder().decode(SubsonicResponse<PingResponse>.self, from: data)
        dump(jsonResponse) // and we can decode that response into a struct!
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
