@testable import Dromio
import Testing
import MediaPlayer
import WaitWhile

struct PlayerTrampolineTests {
    let subject = PlayerTrampoline()
    let player = MockPlayerTrampolineTarget()
    let event = MockSkipIntervalCommandEvent()

    init() {
        subject.player = player
    }

    @Test("doPlay: calls player doPlay, update false")
    func doPlay() async {
        let result = subject.doPlay(event)
        await #while(player.methodsCalled.isEmpty)
        #expect(player.methodsCalled == ["doPlay(updateOnly:)"])
        #expect(player.updateOnly == false)
        #expect(result == .success)
    }

    @Test("doPause: calls player doPause")
    func doPause() async {
        let result = subject.doPause(event)
        await #while(player.methodsCalled.isEmpty)
        #expect(player.methodsCalled == ["doPause()"])
        #expect(result == .success)
    }

    @Test("doSkipBack: calls play skip, negative interval")
    func doSkipBack() async {
        let result = subject.doSkipBack(event)
        await #while(player.methodsCalled.isEmpty)
        #expect(player.methodsCalled == ["skip(interval:)"])
        #expect(player.interval == -30)
        #expect(result == .success)
    }

    @Test("doSkipForward: calls play skip, positive interval")
    func doSkipForward() async {
        let result = subject.doSkipForward(event)
        await #while(player.methodsCalled.isEmpty)
        #expect(player.methodsCalled == ["skip(interval:)"])
        #expect(player.interval == 30)
        #expect(result == .success)
    }
}
