import XCTest
@testable import HarborCore

final class AppVersionAndSafetyTests: XCTestCase {
    func testVersionUsesExactBundleMetadata() {
        let version=AppVersion(info:["CFBundleShortVersionString":"0.2.3","CFBundleVersion":"15"])
        XCTAssertEqual(version.version,"0.2.3"); XCTAssertEqual(version.build,"15")
    }
    func testUnavailableVersionIsNeverAnOlderHardcodedVersion() {
        let version=AppVersion(info:[:]); XCTAssertEqual(version.version,"?");XCTAssertEqual(version.build,"?")
    }
    func testDetachedOccurrenceRecurrenceAndParticipantsAreAlwaysUnsafeCopies() {
        XCTAssertFalse(CopyIdentitySafety.isUnsafe(hasAttendees:false,organizerPresent:false,hasRecurrenceRules:false,isDetached:false))
        for flag in 0..<4 {
            XCTAssertTrue(CopyIdentitySafety.isUnsafe(hasAttendees:flag==0,organizerPresent:flag==1,hasRecurrenceRules:flag==2,isDetached:flag==3))
        }
    }
}
