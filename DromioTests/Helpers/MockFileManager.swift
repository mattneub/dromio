@testable import Dromio
import Foundation

final class MockFileManager: FileManagerType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var whatToThrow: (any Error)?
    nonisolated(unsafe) var urls = [URL: [URL]]() // directory: contents
    nonisolated(unsafe) var moveAt: URL?
    nonisolated(unsafe) var moveTo: URL?
    nonisolated(unsafe) var removeAt = [URL]()

    func moveItem(
        at srcURL: URL,
        to dstURL: URL
    ) throws {
        methodsCalled.append(#function)
        moveAt = srcURL
        moveTo = dstURL
        if let whatToThrow {
            throw whatToThrow
        }
    }
    
    func removeItem(at url: URL) throws {
        methodsCalled.append(#function)
        removeAt.append(url)
        if let whatToThrow {
            throw whatToThrow
        }
    }
    
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        methodsCalled.append(#function)
        if let whatToThrow, (urls[url]?.isEmpty ?? true) {
            throw whatToThrow
        }
        return urls[url] ?? []
    }
}
