import XCTest
@testable import HarborCore

final class PendingWriteJournalTests: XCTestCase {
    func fixture() -> (URL, PendingWriteJournal) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (dir, PendingWriteJournal(file: dir.appendingPathComponent("pending.json")))
    }
    func intent() -> PendingWriteIntent { .init(ruleID: UUID(), destinationID: "fake", markers: ["marker"], existingIDs: []) }
    func testIntentSurvivesRestartAndBlocksRetry() throws {
        let (dir, journal) = fixture(); defer { try? FileManager.default.removeItem(at: dir) }
        let original = intent(); try journal.begin(original)
        let reopened = PendingWriteJournal(file: journal.file)
        XCTAssertEqual(try reopened.pending(), original)
        XCTAssertThrowsError(try reopened.begin(intent()))
        XCTAssertEqual(try reopened.pending(), original)
    }
    func testWrongCompletionDoesNotClearIntent() throws {
        let (dir, journal) = fixture(); defer { try? FileManager.default.removeItem(at: dir) }
        let original = intent(); try journal.begin(original)
        XCTAssertThrowsError(try journal.complete(attemptID: UUID()))
        XCTAssertEqual(try journal.pending(), original)
    }
    func testConfirmedAttemptCanComplete() throws {
        let (dir, journal) = fixture(); defer { try? FileManager.default.removeItem(at: dir) }
        let original = intent(); try journal.begin(original)
        try journal.complete(attemptID: original.id)
        XCTAssertNil(try journal.pending()); XCTAssertNoThrow(try journal.begin(intent()))
    }
    func testCorruptJournalNeverAllowsRetry() throws {
        let (dir, journal) = fixture(); defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: journal.file)
        XCTAssertThrowsError(try journal.pending()); XCTAssertThrowsError(try journal.begin(intent()))
    }
}
