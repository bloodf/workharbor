import XCTest
@testable import HarborCore

final class ReconciliationTests: XCTestCase {
    let install = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    var rule: MirrorRule { var r = MirrorRule(); r.sourceID = "apple"; r.destinationID = "google"; return r }
    func event(_ title: String = "Segredo", start: Date = Date(timeIntervalSince1970: 1_790_000_000)) -> EventValue {
        EventValue(title: title, start: start, end: start.addingTimeInterval(3600), timeZone: "America/Sao_Paulo", notes: "Dados pessoais", location: "Clínica")
    }
    func plan(_ r: MirrorRule, _ sources: [SourceEvent], _ copies: [OwnedEvent] = []) throws -> [PlannedChange] {
        try Reconciler.plan(installation: install, rule: r, snapshot: SyncSnapshot(sources: sources, copies: copies))
    }
    func testBusyRedactsAndAppliesBuffers() throws {
        let r = rule; let input = event()
        let result = try plan(r, [SourceEvent(key: "1", value: input)]).first!.after!
        XCTAssertEqual(result.title, "Busy"); XCTAssertNil(result.notes); XCTAssertNil(result.location)
        XCTAssertEqual(result.start, input.start.addingTimeInterval(-900)); XCTAssertEqual(result.end, input.end.addingTimeInterval(900))
        XCTAssertEqual(result.timeZone, input.timeZone)
    }
    func testDetailsPreserveFieldsAndIgnoreBuffers() throws {
        var r = rule; r.mode = .details
        let input = event()
        XCTAssertEqual(try plan(r, [SourceEvent(key: "1", value: input)]).first?.after, input)
    }
    func testAllDayAcrossDSTPreservesExclusiveEnd() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8))!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        XCTAssertEqual(end.timeIntervalSince(start), 23 * 3600)
        let input = EventValue(title: "Viagem", start: start, end: end, allDay: true, timeZone: calendar.timeZone.identifier)
        let result = try plan(rule, [.init(key: "1", value: input)]).first!.after!
        XCTAssertEqual(result.start, start); XCTAssertEqual(result.end, end); XCTAssertTrue(result.allDay)
    }
    func testTimedEventAcrossDSTUsesAbsoluteMinuteBuffers() throws {
        let input = event(start: ISO8601DateFormatter().date(from: "2026-11-01T05:45:00Z")!)
        let result = Reconciler.transformed(input, by: rule)
        XCTAssertEqual(result.end.timeIntervalSince(result.start), 5400)
    }
    func testReopeningReusesMarkerAndConverges() throws {
        let r = rule; let source = SourceEvent(key: "series|occurrence", value: event())
        let first = try plan(r, [source])[0]
        let reopenedRule = try JSONDecoder().decode(MirrorRule.self, from: JSONEncoder().encode(r))
        let copy = OwnedEvent(id: "persisted-id", marker: first.marker, value: first.after!)
        XCTAssertTrue(try plan(reopenedRule, [source], [copy]).isEmpty)
    }
    func testChangedSourceUpdatesCopyOnly() throws {
        let r = rule; let source = SourceEvent(key: "1", value: event())
        let original = try plan(r, [source])[0]
        var changed = source.value; changed.start += 3600; changed.end += 3600
        let result = try plan(r, [.init(key: "1", value: changed)], [.init(id: "copy", marker: original.marker, value: original.after!)])
        XCTAssertEqual(result.count, 1); XCTAssertEqual(result[0].kind, .update); XCTAssertEqual(result[0].existingID, "copy")
    }
    func testRecurrencesAndMovedExceptionHaveSeparateIdentity() throws {
        let r = rule
        let sources = [SourceEvent(key: "series|anchor1", value: event()), SourceEvent(key: "series|anchor2", value: event(start: event().start + 86400))]
        let first = try plan(r, sources)
        XCTAssertEqual(Set(first.map(\.marker)).count, 2)
        let copies = first.enumerated().map { OwnedEvent(id: String($0.offset), marker: $0.element.marker, value: $0.element.after!) }
        var moved = sources[1].value; moved.start += 7200; moved.end += 7200
        let changes = try plan(r, [sources[0], .init(key: sources[1].key, value: moved)], copies)
        XCTAssertEqual(changes.map(\.kind), [.update])
    }
    func testMissingOccurrencePreservesItsCopy() throws {
        let r = rule; let sources = [SourceEvent(key: "series|1", value: event()), SourceEvent(key: "series|2", value: event())]
        let initial = try plan(r, sources)
        let copies = initial.enumerated().map { OwnedEvent(id: String($0.offset), marker: $0.element.marker, value: $0.element.after!) }
        let result = try plan(r, [sources[0]], copies)
        XCTAssertTrue(result.isEmpty)
        let unresolved = Reconciler.unmatchedCopies(installation: install, rule: r, snapshot: .init(sources: [sources[0]], copies: copies))
        XCTAssertEqual(unresolved.count, 1)
        XCTAssertEqual(unresolved[0].marker, Reconciler.marker(installation: install, rule: r, sourceKey: "series|2"))
    }
    func testForeignEventsNeverDeleted() throws {
        let r = rule
        let foreign = [OwnedEvent(id: "original", marker: "https://example.com", value: event()), OwnedEvent(id: "other-install", marker: Reconciler.marker(installation: UUID(), rule: r, sourceKey: "1"), value: event())]
        XCTAssertTrue(try plan(r, [], foreign).isEmpty)
    }
    func testAnotherRuleCopiesAreUntouched() throws {
        let r = rule
        let foreign = OwnedEvent(id: "other-rule", marker: Reconciler.marker(installation: install, rule: rule, sourceKey: "1"), value: event())
        XCTAssertTrue(try plan(r, [], [foreign]).isEmpty)
    }
    func testDuplicatesConvergeWithoutCreating() throws {
        let r = rule; let sources = [SourceEvent(key: "1", value: event())]; let create = try plan(r, sources)[0]
        let copies = ["a", "b"].map { OwnedEvent(id: $0, marker: create.marker, value: create.after!) }
        let result = try plan(r, sources, copies)
        XCTAssertEqual(result.count, 1); XCTAssertEqual(result[0].kind, .delete); XCTAssertEqual(result[0].existingID, "b")
    }
    func testAlreadyMirroredSourcesExcluded() throws {
        XCTAssertTrue(try plan(rule, [.init(key: "1", value: event(), isMirror: true)]).isEmpty)
    }
    func testParticipantOrRecurrenceCopyBlocksWholePlan() throws {
        let r = rule; let marker = Reconciler.marker(installation: install, rule: r, sourceKey: "1")
        XCTAssertThrowsError(try plan(r, [], [.init(id: "copy", marker: marker, value: event(), hasParticipants: true)]))
    }
    func testIncompleteSnapshotCannotDelete() {
        let r = rule
        XCTAssertThrowsError(try Reconciler.plan(installation: install, rule: r, snapshot: .init(sources: [], copies: [.init(id: "copy", marker: Reconciler.marker(installation: install, rule: r, sourceKey: "1"), value: event())], complete: false)))
    }
    func testDuplicateOccurrenceIDsBlockPreview() {
        XCTAssertThrowsError(try plan(rule, [.init(key: "same", value: event()), .init(key: "same", value: event())]))
    }
    func testRemovedOrReadOnlyCalendarBlocks() {
        XCTAssertThrowsError(try Reconciler.validate([rule], calendars: []))
        XCTAssertThrowsError(try Reconciler.validate([rule], calendars: [.init(id: "apple", name: "Apple", writable: true), .init(id: "google", name: "Google", writable: false)]))
    }
    func testSelfLoopCycleAndChainingBlocked() {
        var a = rule; a.destinationID = "apple"
        let calendars: [CalendarInfo] = [.init(id: "apple", name: "Apple", writable: true), .init(id: "google", name: "Google", writable: true)]
        XCTAssertThrowsError(try Reconciler.validate([a], calendars: calendars))
        var b = rule; b.sourceID = "google"; b.destinationID = "apple"
        XCTAssertThrowsError(try Reconciler.validate([rule, b], calendars: calendars))
    }
    func testDuplicateRoutesBlocked() {
        XCTAssertThrowsError(try Reconciler.validate([rule, rule], calendars: [.init(id: "apple", name: "Apple", writable: true), .init(id: "google", name: "Google", writable: true)]))
    }
    func testInvalidEventRangeBlocked() {
        var input = event(); input.end = input.start
        XCTAssertThrowsError(try plan(rule, [.init(key: "1", value: input)]))
    }

    func testEmptyLocalSourceDoesNotDeleteBusyCopy() throws {
        let r = rule; let change = try plan(r, [.init(key: "1", value: event())])[0]
        let copy = OwnedEvent(id: "copy", marker: change.marker, value: change.after!)
        XCTAssertTrue(try plan(r, [], [copy]).isEmpty)
    }
    func testMissingDetailsCopyIsPreservedWithoutDeleting() throws {
        var r = rule; r.mode = .details
        let marker = Reconciler.marker(installation: install, rule: r, sourceKey: "1")
        XCTAssertTrue(try plan(r, [], [.init(id: "copy", marker: marker, value: event())]).isEmpty)
    }
    func testBusyRedactsOrphanWithoutChangingIntervalOrDoubleBuffer() throws {
        let r = rule; let old = event(start: Date(timeIntervalSince1970: 1_000))
        let copy = OwnedEvent(id: "old", marker: Reconciler.marker(installation: install, rule: r, sourceKey: "old"), value: old)
        let changes = try plan(r, [], [copy])
        XCTAssertEqual(changes.count, 1); XCTAssertEqual(changes[0].kind, .update)
        XCTAssertEqual(changes[0].after?.title, "Busy")
        XCTAssertNil(changes[0].after?.notes); XCTAssertNil(changes[0].after?.location)
        XCTAssertEqual(changes[0].after?.start, old.start); XCTAssertEqual(changes[0].after?.end, old.end)
        let redacted = OwnedEvent(id: copy.id, marker: copy.marker, value: changes[0].after!)
        XCTAssertTrue(try plan(r, [], [redacted]).isEmpty)
    }
    func testOrphanRedactionDoesNotTouchOtherInstallation() throws {
        let r = rule
        let foreign = OwnedEvent(id: "foreign", marker: Reconciler.marker(installation: UUID(), rule: r, sourceKey: "1"), value: event())
        XCTAssertTrue(try plan(r, [], [foreign]).isEmpty)
        XCTAssertTrue(Reconciler.unmatchedCopies(installation: install, rule: r, snapshot: .init(sources: [], copies: [foreign])).isEmpty)
    }
    func testOrphanWithParticipantsBlocksRedaction() {
        let r = rule
        let copy = OwnedEvent(id: "copy", marker: Reconciler.marker(installation: install, rule: r, sourceKey: "1"), value: event(), hasParticipants: true)
        XCTAssertThrowsError(try plan(r, [], [copy]))
    }
    func testReappearingSourceReusesPreservedCopy() throws {
        let r = rule; let source = SourceEvent(key: "stable", value: event())
        let change = try plan(r, [source])[0]
        let copy = OwnedEvent(id: "retained", marker: change.marker, value: change.after!)
        XCTAssertTrue(try plan(r, [], [copy]).isEmpty)
        XCTAssertTrue(try plan(r, [source], [copy]).isEmpty)
    }

    func testBusyRedactsEveryDuplicateBeforeOfferingOptionalDeletion() throws {
        let r = rule; let source = SourceEvent(key: "1", value: event())
        let marker = Reconciler.marker(installation: install, rule: r, sourceKey: source.key)
        let copies = ["a", "b"].map { OwnedEvent(id: $0, marker: marker, value: source.value) }
        let first = try plan(r, [source], copies)
        XCTAssertEqual(first.count, 2)
        XCTAssertTrue(first.allSatisfy { $0.kind == .update && $0.after?.title == "Busy" && $0.after?.notes == nil && $0.after?.location == nil })
        let clean = first.map { OwnedEvent(id: $0.existingID!, marker: $0.marker, value: $0.after!) }
        let second = try plan(r, [source], clean)
        XCTAssertEqual(second.count, 1); XCTAssertEqual(second[0].kind, .delete)
        XCTAssertEqual(second[0].existingID, "b")
    }
}
