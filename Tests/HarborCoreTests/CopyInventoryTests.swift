import XCTest
@testable import HarborCore
final class CopyInventoryTests:XCTestCase {
    func testUpdatingDuplicateKeepsCanonicalIdentity() {
        XCTAssertEqual(CopyInventory.reconcile(existing:["m":"canonical"],saved:["m":["duplicate"]],copies:[],deletedIDs:[]),["m":"canonical"])
    }
    func testDeletingDuplicateKeepsCanonicalIdentity() {
        XCTAssertEqual(CopyInventory.reconcile(existing:["m":"canonical"],saved:[:],copies:[],deletedIDs:["duplicate"]),["m":"canonical"])
    }
    func testNewCopyIsRecorded() {
        XCTAssertEqual(CopyInventory.reconcile(existing:[:],saved:["m":["created"]],copies:[],deletedIDs:[]),["m":"created"])
    }
    func testExplicitlyDeletedCanonicalDoesNotRemain() {
        XCTAssertTrue(CopyInventory.reconcile(existing:["m":"deleted"],saved:[:],copies:[],deletedIDs:["deleted"]).isEmpty)
    }
}
