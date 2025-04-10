@testable import Dromio
import Testing
import UIKit

@MainActor
struct BackgroundTaskOperationMakerTests {
    @Test("what the maker makes, by default, is a background task operation")
    func make() {
        let subject = BackgroundTaskOperationMaker()
        let product = subject.make(whatToDo: { return () }, cleanup: nil)
        #expect(product is BackgroundTaskOperation<Void>)
    }
}
