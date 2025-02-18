import Foundation

struct SubsonicResponse<T: Codable>: Codable {
    let subsonicResponse: T
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

/*
 // ok, smart boy, let's see you fetch the list of albums
 urlComponents.path = "/rest/getAlbumList2"
 queries.append(.init(name: "type", value: "alphabeticalByName"))
 urlComponents.queryItems = queries
 do {
 let config = URLSessionConfiguration.ephemeral
 let session = URLSession(configuration: config)
 guard let url = urlComponents.url else { return }
 let request = URLRequest(url: url)
 guard let (data, response) = try? await session.data(for: request) else { return }
 print(response)
 // should check here: is response status code 200?
 guard let dataString = String(data: data, encoding: .utf8) else { return }
 print(dataString)
 // yep, we can get albums! however, I got a very short list (ten)
 // max is 500 ("size"), after that you need to supply an "offset"
 }
 */

