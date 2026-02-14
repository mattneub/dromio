@testable import Dromio
import Testing
import MediaPlayer

struct PlayerTrampolineTests {
    let subject = PlayerTrampoline()
    let player = MockPlayerTrampolineTarget()
    let event = MockSkipIntervalCommandEvent()

    init() {
        subject.player = player
    }

    @Test("doPlay: calls player doPlay, update false")
    func doPlay() {
        let result = subject.doPlay(event)
        #expect(player.methodsCalled == ["doPlay(updateOnly:)"])
        #expect(player.updateOnly == false)
        #expect(result == .success)
    }

    @Test("doPause: calls player doPause")
    func doPause() {
        let result = subject.doPause(event)
        #expect(player.methodsCalled == ["doPause()"])
        #expect(result == .success)
    }

    @Test("doSkipBack: calls play skip, forward false, event same event, result is player's result")
    func doSkipBack() {
        player.status = .deviceNotFound
        let result = subject.doSkipBack(event)
        #expect(player.methodsCalled == ["skip(forward:event:)"])
        #expect(player.forward == false)
        #expect(player.event === event)
        #expect(result == .deviceNotFound)
    }

    @Test("doSkipForward: calls play skip, forward true, event same event, result is player's result")
    func doSkipForward() {
        player.status = .deviceNotFound
        let result = subject.doSkipForward(event)
        #expect(player.methodsCalled == ["skip(forward:event:)"])
        #expect(player.forward == true)
        #expect(player.event === event)
        #expect(result == .deviceNotFound)
    }
}
