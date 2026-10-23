import XCTest
@testable import HarborCore
final class ProcessLockTests:XCTestCase {
    func testSecondInstanceCannotAcquireAndExitReleasesLock() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:dir)}
        let file=dir.appendingPathComponent("instance.lock")
        var first:ProcessLock?=try ProcessLock(file:file);XCTAssertNotNil(first)
        XCTAssertThrowsError(try ProcessLock(file:file));first=nil
        let next=try ProcessLock(file:file);XCTAssertNotNil(next)
    }
}
