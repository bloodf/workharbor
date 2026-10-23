import XCTest
@testable import HarborCore
final class IdentityInspectionTests:XCTestCase {
    let expected=["marker":"old"]
    func rows(_ observations:[CopyIdentityObservation], direct:[String:CopyIdentityObservation]=[:])->[CopyIdentityFinding] {
        IdentityInspection.inspect(expected:expected,destinationID:"dest",direct:direct,searched:observations)
    }
    var good:CopyIdentityObservation { .init(id:"new",marker:"marker",calendarID:"dest") }
    func testMissingDoesNotMeanDeleted() throws {
        let r=rows([]);XCTAssertEqual(r.first?.state,.missing)
        XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:expected,reviewed:r,current:r,selected:["marker"],confirmed:true))
    }
    func testUniqueMarkerRebindsOnlyMetadata() throws {
        let r=rows([good]);XCTAssertEqual(r.first?.state,.recoverable)
        let original=["marker":"old","untouched":"other"]
        let fixed=try IdentityInspection.repairedInventory(original:original,reviewed:r,current:r,selected:["marker"],confirmed:true)
        XCTAssertEqual(fixed,["marker":"new","untouched":"other"])
    }
    func testRepeatedChunkResultsDeduplicateByID() {XCTAssertEqual(rows([good,good]).first?.state,.recoverable)}
    func testEmptyReplacementIDIsUnsafe() {XCTAssertEqual(rows([.init(id:"",marker:"marker",calendarID:"dest")]).first?.state,.unsafe)}
    func testDuplicateMarkersBlock() {XCTAssertEqual(rows([good,.init(id:"second",marker:"marker",calendarID:"dest")]).first?.state,.ambiguous)}
    func testWrongCalendarAndMarkerDoNotRecover() {
        XCTAssertEqual(rows([.init(id:"new",marker:"marker",calendarID:"wrong")]).first?.state,.missing)
        XCTAssertEqual(rows([.init(id:"new",marker:nil,calendarID:"dest")]).first?.state,.missing)
    }
    func testUnsafeCopyBlocks() {XCTAssertEqual(rows([.init(id:"new",marker:"marker",calendarID:"dest",unsafe:true)]).first?.state,.unsafe)}
    func testDirectMismatchBlocksEvenWhenSearchHasMatch() {
        XCTAssertEqual(rows([good],direct:["old":.init(id:"old",marker:nil,calendarID:"dest")]).first?.state,.mismatch)
    }
    func testStaleInspectionOrInventoryCannotRepair() {
        let r=rows([good]);XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:expected,reviewed:r,current:rows([]),selected:["marker"],confirmed:true))
        XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:["marker":"changed"],reviewed:r,current:r,selected:["marker"],confirmed:true))
        XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:expected,reviewed:r,current:r,selected:["marker"],confirmed:false))
    }
    func testRepairIsIdempotent() {
        let current=IdentityInspection.inspect(expected:["marker":"new"],destinationID:"dest",direct:["new":good],searched:[good])
        XCTAssertEqual(current.first?.state,.located)
        XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:["marker":"new"],reviewed:current,current:current,selected:["marker"],confirmed:true))
    }
}
