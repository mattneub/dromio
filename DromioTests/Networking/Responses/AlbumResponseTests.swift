@testable import Dromio
import Testing
import Foundation

@MainActor
final class AlbumResponseTests {
    @Test("decodes actual json")
    func albumList2Response() throws {
        let jsonUrl = try #require(
            Bundle(for: Self.self).url(forResource: "subsonic album with song list", withExtension: "json")
        )
        let json = try Data(contentsOf: jsonUrl)
        _ = try JSONDecoder().decode(SubsonicResponse<AlbumResponse>.self, from: json)
    }
}
