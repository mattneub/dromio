import UIKit
@testable import Dromio

final class MockReceiver<T>: Receiver {
    var thingsReceived: [T] = []

    func receive(_ thingReceived: T) async {
        thingsReceived.append(thingReceived)
    }
}

final class MockReceiverPresenter<T, U>: UIViewController, ReceiverPresenter {
    var statePresented: U?
    var statesPresented = [U]()
    var thingsReceived: [T] = []

    func present(_ state: U) async {
        statePresented = state
        statesPresented.append(state)
    }

    func receive(_ thingReceived: T) async {
        thingsReceived.append(thingReceived)
    }
}

final class MockProcessor<T, U, V>: Processor {
    var thingsReceived: [T] = []

    var presenter: (any ReceiverPresenter<V, U>)?

    func receive(_ thingReceived: T) async {
        thingsReceived.append(thingReceived)
    }
}
