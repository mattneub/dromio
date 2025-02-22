@testable import Dromio
import Testing
import Foundation

@MainActor
final class AlbumsList2ResponseTests {
    @Test("decodes actual json")
    func albumList2Response() throws {
        let jsonUrl = try #require(
            Bundle(for: Self.self).url(forResource: "subsonic album list", withExtension: "json")
        )
        let json = try Data(contentsOf: jsonUrl)
        _ = try #require(
            try JSONDecoder().decode(SubsonicResponse<AlbumList2Response>.self, from: json)
        )
    }
}
