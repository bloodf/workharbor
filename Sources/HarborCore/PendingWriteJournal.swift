import Foundation

public struct PendingWriteIntent: Codable, Equatable, Sendable {
    public let id: UUID
    public let ruleID: UUID
    public let destinationID: String
    public let markers: [String]
    public let existingIDs: [String]
    public let createdAt: Date
    public init(ruleID: UUID, destinationID: String, markers: [String], existingIDs: [String]) {
        id = UUID(); self.ruleID = ruleID; self.destinationID = destinationID
        self.markers = markers; self.existingIDs = existingIDs; createdAt = Date()
    }
}
public struct PendingWriteJournal {
    public let file: URL
    public init(file: URL) { self.file = file }
    public func begin(_ intent: PendingWriteIntent) throws {
        guard !FileManager.default.fileExists(atPath: file.path) else {
            throw HarborError.invalid("Tentativa anterior não reconciliada. Repetição bloqueada.")
        }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(intent).write(to: file, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
    public func pending() throws -> PendingWriteIntent? {
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try JSONDecoder().decode(PendingWriteIntent.self, from: Data(contentsOf: file))
    }
    public func complete(attemptID: UUID) throws {
        guard let intent = try pending(), intent.id == attemptID else {
            throw HarborError.invalid("Tentativa de gravação não corresponde ao registro persistido.")
        }
        try FileManager.default.removeItem(at: file)
    }
}
