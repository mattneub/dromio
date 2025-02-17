import Foundation

@MainActor protocol NetworkerType {
    func ping() async -> Bool
}

@MainActor
final class Networker: NetworkerType {
    func ping() async -> Bool {
        guard let url = URLMaker.urlFor(action: "ping") else { return false }
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let request = URLRequest(url: url)
        guard let (data, response) = try? await session.data(for: request) else { return false }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
        guard let jsonResponse = try? JSONDecoder().decode(SubsonicResponse<PingResponse>.self, from: data) else { return false }
        dump(jsonResponse) // and we can decode that response into a struct!
        guard jsonResponse.subsonicResponse.status == "ok" else { return false }
        return true
    }
}
