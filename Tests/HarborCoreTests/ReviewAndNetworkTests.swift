import XCTest
@testable import HarborCore

final class ReviewAndNetworkTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_790_000_000)
    let snapshot = SyncSnapshot(sources: [], copies: [])
    func testRevokedPermissionPreventsAuthorizedWrite() {
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: false, createdAt: now, now: now, reviewed: snapshot, current: snapshot))
    }
    func testDemoAndUnconfirmedReviewCannotWrite() {
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: true, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: snapshot))
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: false, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: snapshot))
    }
    func testExpiredOrClockReversedReviewCannotWrite() {
        for date in [now.addingTimeInterval(300), now.addingTimeInterval(-1)] {
            XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: date, reviewed: snapshot, current: snapshot))
        }
    }
    func testChangedOrIncompleteSnapshotRequiresReview() {
        var current = snapshot; current.complete = false
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: current))
        current.complete = true
        current.sources.append(.init(key: "new", value: .init(title: "new", start: now, end: now + 3600)))
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: current))
    }
    func testIdenticalUnlocatedIDsStillBlockManualWrite() {
        let missing = SyncSnapshot(sources: [], copies: [], unlocatedTrackedIDs: ["missing-local-id"])
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: missing, current: missing))
    }
    func testUnlocatedIDInEitherSnapshotBlocksWrite() {
        let missing = SyncSnapshot(sources: [], copies: [], unlocatedTrackedIDs: ["missing-local-id"])
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: missing, current: snapshot))
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: missing))
    }
    func testUnchangedFreshAuthorizedReviewPasses() {
        XCTAssertNoThrow(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, createdAt: now, now: now, reviewed: snapshot, current: snapshot))
    }
    func testAllDayIdentitySurvivesSystemTimeZoneChange() {
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var la = tokyo; la.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let day = DateComponents(year: 2026, month: 10, day: 22)
        let a = OccurrenceIdentity.key(itemID: "series", occurrence: tokyo.date(from: day), allDay: true, calendar: tokyo)
        let b = OccurrenceIdentity.key(itemID: "series", occurrence: la.date(from: day), allDay: true, calendar: la)
        XCTAssertEqual(a, b)
    }
    func testTimedIdentityDoesNotChangeAcrossZones() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        XCTAssertEqual(OccurrenceIdentity.key(itemID: "series", occurrence: now, allDay: false), OccurrenceIdentity.key(itemID: "series", occurrence: now, allDay: false, calendar: calendar))
    }
    func testProviderStrippingMarkerBlocksRecreation() {
        XCTAssertThrowsError(try TrackedCopyGuard.validate(expectedMarker: "own-marker", actualMarker: nil, expectedCalendar: "destination", actualCalendar: "destination"))
    }
    func testMovedTrackedCopyBlocksRecreation() {
        XCTAssertThrowsError(try TrackedCopyGuard.validate(expectedMarker: "own-marker", actualMarker: "own-marker", expectedCalendar: "destination", actualCalendar: "other"))
    }
    func testOfflineCalendarWriteIsBlocked() {
        XCTAssertThrowsError(try ReviewGuard.validate(confirmed: true, demo: false, fullAccess: true, networkAvailable: false, createdAt: now, now: now, reviewed: snapshot, current: snapshot))
    }
}
