@testable import Dromio
import Testing

@MainActor
struct AlbumsProcessorTests {
    let subject = AlbumsProcessor()
    let presenter = MockReceiverPresenter<Void, AlbumsState>()
    let requestMaker = MockRequestMaker()

    init() {
        subject.presenter = presenter
        services.requestMaker = requestMaker
    }

    @Test("mutating the state presents the state")
    func state() {
        subject.state.albums.append(.init(id: "1", name: "Yoho", songCount: 30))
        #expect(presenter.statePresented?.albums.first == .init(id: "1", name: "Yoho", songCount: 30))
    }

    @Test("receive initialData: sends `getAlbumList` to request maker")
    func receiveInitialData() async {
        await subject.receive(.initialData)
        #expect(requestMaker.methodsCalled == ["getAlbumList()"])
    }

}
