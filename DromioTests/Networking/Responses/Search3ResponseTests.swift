@testable import Dromio
import Testing
import Foundation

final class Search3ResponseTests {
    @Test("decodes actual json")
    func search3Response() throws {
        let jsonUrl = try #require(
            #bundle.url(forResource: "subsonic artist list via search3", withExtension: "json")
        )
        let json = try Data(contentsOf: jsonUrl)
        _ = try JSONDecoder().decode(SubsonicResponse<Search3Response>.self, from: json)
    }
}
