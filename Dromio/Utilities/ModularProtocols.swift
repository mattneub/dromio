/*
 This is the basis for our mini-Pentimento architecture. A view or view controller is a presenter;
 the logic goes into the corresponding processor. A view or view controller sends an _action_ to
 the processor via `receive`. The processor sends a _state_ to the presenter via `present`.

 Sometimes we want the presenter to _do_ something rather than expressing a static state. For that,
 the processor sends an _effect_ to the presenter via `receive`.

 See https://livefront.com/pentimento/
 */

// TODO: I expect that in all the places where I have created an async alternative, we will
// eventually adopt it every and destroy the non-async original.

/// Protocol for classes with a `receive` method; this allows us to slot a mock in place of
/// a processor or presenter, for testing. `Received` should be an action or effect enum.
@MainActor
protocol Receiver<Received>: AnyObject {
    associatedtype Received
    func receive(_: Received) async
}

/// Extension with injection so that if a receiver doesn't actually receive, it doesn't
/// have to write a `receive` a method.
extension Receiver where Received == Void {
    func receive(_: Void) async {}
}

/// Protocol for classes with a `present` method; this allows us to slot a mock in place of
/// a processor or presenter, for testing. `State` should be a state struct.
@MainActor
protocol Presenter<State>: AnyObject {
    associatedtype State
    func present(_: State)
}

/// Async version of the preceding.
/// Protocol for classes with a `present` method; this allows us to slot a mock in place of
/// a processor or presenter, for testing. `State` should be a state struct.
@MainActor
protocol AsyncPresenter<State>: AnyObject {
    associatedtype State
    func present(_: State) async
}

/// Compositional protocol for types that adopt both Receiver and Presenter (it is not currently
/// possible to do this with an actual composition operator).
@MainActor
protocol ReceiverPresenter<Received, State>: Receiver, Presenter {}

/// Async version of the preceding.
/// Compositional protocol for types that adopt both Receiver and Presenter (it is not currently
/// possible to do this with an actual composition operator).
@MainActor
protocol AsyncReceiverPresenter<Received, State>: Receiver, AsyncPresenter {}

/// A Processor is a Receiver that also has a `presenter` property.
@MainActor
protocol Processor<Received, PresenterState, Effect>: Receiver {
    associatedtype PresenterState
    associatedtype Effect
    var presenter: (any ReceiverPresenter<Effect, PresenterState>)? { get set }
}

/// Async version of the preceding.
/// A Processor is a Receiver that also has a `presenter` property.
@MainActor
protocol AsyncProcessor<Received, PresenterState, Effect>: Receiver {
    associatedtype PresenterState
    associatedtype Effect
    var presenter: (any AsyncReceiverPresenter<Effect, PresenterState>)? { get set }
}
