@testable import Dromio
import Testing
import Foundation

@MainActor
struct ResponseValidatorTests {
    let subject = ResponseValidator()

    @Test("validateResponse: throws if the server type is not navidrome")
    func notNavidrome() async throws {
        let response = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "whoever", // *
                serverVersion: "1",
                openSubsonic: true,
                error: nil
            )
        )
        await #expect {
            try await subject.validateResponse(response)
        } throws: { error in
            error as! NetworkerError == .message("The server does not appear to be a Navidrome server.")
        }
    }

    @Test("validateResponse: throws if the status is not ok, with error")
    func notOkError() async throws {
        let response = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "notok", // *
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                error: SubsonicError(code: 1, message: "life is hard")
            )
        )
        await #expect {
            try await subject.validateResponse(response)
        } throws: { error in
            error as! NetworkerError == .message("life is hard")
        }
    }

    @Test("validateResponse: throws if the status is not ok, no error")
    func notOkNoError() async throws {
        let response = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "notok", // *
                version: "1",
                type: "navidrome",
                serverVersion: "1",
                openSubsonic: true,
                error: nil
            )
        )
        await #expect {
            try await subject.validateResponse(response)
        } throws: { error in
            error as! NetworkerError == .message("We got a failed status from the Navidrome server.")
        }
    }

    @Test("validateResponse: throws if the Navidrome version is not high enough")
    func navidromeVersionTooLow() async {
        let response = SubsonicResponse(
            subsonicResponse: PingResponse(
                status: "ok",
                version: "1",
                type: "navidrome",
                serverVersion: "0.54.2", // *
                openSubsonic: true,
                error: nil
            )
        )
        await #expect {
            try await subject.validateResponse(response)
        } throws: { error in
            error as! NetworkerError == .message("The server version of Navidrome is not high enough.")
        }
    }

}
