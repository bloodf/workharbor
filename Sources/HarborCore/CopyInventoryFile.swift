import Foundation

/// Only local marker -> identifier metadata. Never reads calendar event contents.
public struct CopyInventoryFile {
    public let file: URL
    public init(file: URL) { self.file = file }

    /// A missing file is valid only before the first inventory has existed.
    public func validatedBytes(expected: [String: String], mustExist: Bool) throws -> Data? {
        let bytes: Data
        do { bytes = try Data(contentsOf: file) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            guard !mustExist, expected.isEmpty else { throw error }
            return nil
        }
        let decoded = try JSONDecoder().decode([String: String].self, from: bytes)
        guard decoded == expected else { throw HarborError.invalid("Tracking data changed on disk. Writes are blocked; restart and inspect again.") }
        return bytes
    }

    /// Save exact original bytes before changing local IDs. Existing backups are never overwritten.
    @discardableResult
    public func reconnect(expectedBytes: Data, repaired: [String: String]) throws -> URL {
        func verify() throws {
            guard try Data(contentsOf: file) == expectedBytes else {
                throw HarborError.invalid("Tracking data changed during inspection. No recovery was saved.")
            }
        }
        try verify()
        let encoded = try JSONEncoder().encode(repaired)
        let backup = file.deletingLastPathComponent().appendingPathComponent("copies-before-reconnect-" + UUID().uuidString + ".json")
        try expectedBytes.write(to: backup, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backup.path)
        try verify()
        try encoded.write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        return backup
    }
}
