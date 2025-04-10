import Foundation

/// Protocol that wraps the File Manager, so we can mock it for testing.
protocol FileManagerType: AnyObject, Sendable {
    func moveItem(
        at srcURL: URL,
        to dstURL: URL
    ) throws
    func removeItem(at URL: URL) throws
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
}

extension FileManager: FileManagerType, @retroactive @unchecked Sendable {}

