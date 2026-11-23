@testable import Dromio
import Testing
import Foundation

final class AlbumResponseTests {
    @Test("decodes actual json")
    func albumList2Response() throws {
        let jsonUrl = try #require(
            #bundle.url(forResource: "subsonic album with song list", withExtension: "json")
        )
        let json = try Data(contentsOf: jsonUrl)
        _ = try JSONDecoder().decode(SubsonicResponse<AlbumResponse>.self, from: json)
    }
}
