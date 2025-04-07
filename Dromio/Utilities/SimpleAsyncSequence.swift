import Foundation

/*
 Incredibly, Apple has provided no way to make first-order sequence functions such as `map` take
 async functions. So to allow this, we need a way to turn a sequence into an AsyncSequence and
 then turn the AsyncSequence back into a normal sequence.
 */

/// AsyncSequence initialized from a normal sequence (an array, in fact).
struct SimpleAsyncSequence<T: Sendable>: AsyncSequence, AsyncIteratorProtocol, Sendable {
    private var sequenceIterator: IndexingIterator<[T]>

    /// Initialize the async sequence from an array.
    /// - Parameter array: The array.
    init(array: [T]) {
        self.sequenceIterator = array.makeIterator()
    }

    mutating func next() async -> T? {
        sequenceIterator.next()
    }

    func makeAsyncIterator() -> SimpleAsyncSequence { self }
}

/// Extension that turns an AsyncSequence into a normal sequence.
extension AsyncSequence where Element: Sendable {
    func array() async throws -> [Element] {
        try await reduce(into: []) { $0.append($1) }
    }
}

