import Foundation

struct SimpleAsyncSequence<T: Sendable>: AsyncSequence, AsyncIteratorProtocol, Sendable {
    private var sequenceIterator: IndexingIterator<[T]>
    init(array: [T]) {
        self.sequenceIterator = array.makeIterator()
    }
    mutating func next() async -> T? {
        sequenceIterator.next()
    }
    func makeAsyncIterator() -> SimpleAsyncSequence { self }
}

extension AsyncSequence where Element: Sendable {
    func array() async throws -> [Element] {
        var result = [Element]()
        for try await item in self {
            result.append(item)
        }
        return result
    }
}

