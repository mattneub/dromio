@testable import Dromio
import Testing
import Foundation

@MainActor
final class SearchResult3ResponseTests {
    @Test("decodes actual json")
    func searchResult3Response() throws {
        let jsonUrl = try #require(
            Bundle(for: Self.self).url(forResource: "subsonic artist list via search3", withExtension: "json")
        )
        let json = try Data(contentsOf: jsonUrl)
        _ = try JSONDecoder().decode(SubsonicResponse<SearchResult3Response>.self, from: json)
    }
}
