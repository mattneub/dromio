/*
 This is the basis for our mini-Pentimento architecture. A view or view controller is a presenter;
 the logic goes into the corresponding processor. A view or view controller sends an _action_ to
 the processor via `receive`. The processor sends a _state_ to the presenter via `present`.

 Sometimes we want the presenter to _do_ something rather than expressing a static state. For that,
 the processor sends an _effect_ to the presenter via `receive`.

 See https://livefront.com/pentimento/
 */

/// Protocol for classes with a `receive` method; this allows us to slot a mock in place of
/// a processor or presenter, for testing. `T` should be an action or effect enum.
@MainActor
protocol Receiver<T>: AnyObject {
    associatedtype T
    func receive(_: T) async
}

/// Protocol for classes with a `present` method; this allows us to slot a mock in place of
/// a processor or presenter, for testing. `U` should be a state struct.
@MainActor
protocol Presenter<U>: AnyObject {
    associatedtype U
    func present(_: U)
}

/// Compositional protocol for types that adopt both Receiver and Presenter (it is not currently
/// possible to do this with an actual composition operator).
@MainActor
protocol ReceiverPresenter<T, U>: Receiver, Presenter {}

/// A Processor is a Receiver that also has a `presenter` property.
@MainActor
protocol Processor<T, U>: Receiver {
    associatedtype U
    var presenter: (any Presenter<U>)? { get set }
}
