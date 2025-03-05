import Foundation
@testable import Dromio
import Testing

struct EnsureNoBreakSpaceTests {
    @Test
    func stringNormal() {
        let subject: Optional<String> = "howdy"
        #expect(subject.ensureNoBreakSpace == "howdy")
    }

    @Test
    func stringEmpty() {
        let subject: Optional<String> = ""
        #expect(subject.ensureNoBreakSpace == " ")
    }

    @Test
    func stringNil() {
        let subject: Optional<String> = nil
        #expect(subject.ensureNoBreakSpace == " ")
    }

    @Test
    func intNormal() {
        let subject: Optional<Int> = 1
        #expect(subject.ensureNoBreakSpace == "1")
    }

    @Test
    func intZero() {
        let subject: Optional<Int> = 0
        #expect(subject.ensureNoBreakSpace == " ")
    }

    @Test
    func intNil() {
        let subject: Optional<Int> = nil
        #expect(subject.ensureNoBreakSpace == " ")
    }
}
