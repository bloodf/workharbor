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
    func testDirectIdentityStillReportsDuplicateMarkers() {
        let direct=CopyIdentityObservation(id:"old",marker:"marker",calendarID:"dest")
        XCTAssertEqual(rows([direct,good],direct:["old":direct]).first?.state,.ambiguous)
    }
    func testDirectIdentityCannotHideUnsafeObservationDuringScan() {
        let direct=CopyIdentityObservation(id:"old",marker:"marker",calendarID:"dest")
        let changed=CopyIdentityObservation(id:"old",marker:"marker",calendarID:"dest",unsafe:true)
        XCTAssertEqual(rows([changed],direct:["old":direct]).first?.state,.unsafe)
    }
    func testFiniteChunksCoverLeapYearsExactlyWithoutOverlap() throws {
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!
        let start=calendar.date(from:DateComponents(year:2024,month:2,day:29))!
        let end=calendar.date(byAdding:.year,value:4,to:start)!
        let chunks=try IdentityInspection.chunks(in:DateInterval(start:start,end:end),calendar:calendar)
        XCTAssertEqual(chunks.first?.start,start);XCTAssertEqual(chunks.last?.end,end)
        XCTAssertTrue(chunks.allSatisfy {$0.duration > 0 && $0.duration <= 366*86400})
        for (a,b) in zip(chunks,chunks.dropFirst()) {XCTAssertEqual(a.end,b.start)}
    }
    func testDiagnosticRejectsEmptyOrUnboundedSearch() {
        let now=Date()
        XCTAssertThrowsError(try IdentityInspection.chunks(in:DateInterval(start:now,duration:0)))
        XCTAssertThrowsError(try IdentityInspection.chunks(in:DateInterval(start:now,duration:1465*86400)))
        XCTAssertThrowsError(try IdentityInspection.chunks(in:DateInterval(start:.distantPast,end:.distantFuture)))
    }
    func testPartialFinalChunkStopsAtRequestedDate() throws {
        let start=Date(timeIntervalSince1970:1_790_000_000),end=start+400*86400
        let chunks=try IdentityInspection.chunks(in:DateInterval(start:start,end:end))
        XCTAssertEqual(chunks.count,2);XCTAssertEqual(chunks.last?.end,end)
    }
    func testInspectionExpiryAndReversedClockBlockRecovery() {
        let created=Date(timeIntervalSince1970:1_790_000_000)
        XCTAssertThrowsError(try IdentityInspection.validateReview(createdAt:created,now:created+300))
        XCTAssertThrowsError(try IdentityInspection.validateReview(createdAt:created,now:created-1))
    }
    func testFreshInspectionIsValidUntilExpiryBoundary() {
        let created=Date(timeIntervalSince1970:1_790_000_000)
        XCTAssertNoThrow(try IdentityInspection.validateReview(createdAt:created,now:created))
        XCTAssertNoThrow(try IdentityInspection.validateReview(createdAt:created,now:created+299))
    }
    func testDirectIDCanLocateCopyOutsideFiniteSearchWindow() {
        let direct=CopyIdentityObservation(id:"old",marker:"marker",calendarID:"dest")
        XCTAssertEqual(rows([],direct:["old":direct]).first?.state,.located)
    }
    func testMovedCalendarCannotBeReconnectedEvenWhenMarkerSearchFindsAnotherCopy() {
        let moved=CopyIdentityObservation(id:"old",marker:"marker",calendarID:"different")
        XCTAssertEqual(rows([good],direct:["old":moved]).first?.state,.mismatch)
    }
    func testInconsistentSafetyAcrossChunkResultsBlocksReconnection() {
        let unsafe=CopyIdentityObservation(id:"new",marker:"marker",calendarID:"dest",unsafe:true)
        let result=rows([good,unsafe])
        XCTAssertEqual(result.first?.state,.unsafe)
        XCTAssertThrowsError(try IdentityInspection.repairedInventory(original:expected,reviewed:result,current:result,selected:["marker"],confirmed:true))
    }
}
