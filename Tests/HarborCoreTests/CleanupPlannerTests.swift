import XCTest
@testable import HarborCore
final class CleanupPlannerTests:XCTestCase {
    let installation=UUID(),now=Date(timeIntervalSince1970:1000)
    func fixture()->(MirrorRule,SyncSnapshot,String) {
        var rule=MirrorRule();rule.sourceID="personal";rule.destinationID="work"
        let source=SourceEvent(key:"source",value:.init(title:"private",start:now,end:now+3600))
        let marker=Reconciler.marker(installation:installation,rule:rule,sourceKey:source.key),value=Reconciler.transformed(source.value,by:rule)
        let copies=[OwnedEvent(id:"z-tracked",marker:marker,value:value),OwnedEvent(id:"a-duplicate",marker:marker,value:value)]
        return(rule,.init(sources:[source],copies:copies,preferredCopyIDs:[marker:"z-tracked"]),marker)
    }
    func testTrackedUpdatedCopyIsPreservedEvenWhenIDSortsLast() throws {
        let (r,s,_)=fixture();let changes=try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s)
        XCTAssertEqual(changes.map(\.existingID),["a-duplicate"]);XCTAssertTrue(changes.allSatisfy{$0.kind == .delete})
        XCTAssertEqual(try Reconciler.plan(installation:installation,rule:r,snapshot:s).filter{$0.kind == .delete}.map(\.existingID),["a-duplicate"])
    }
    func testAbsenceOfSourceDoesNotDelete() throws {
        let(r,base,_)=fixture();var s=base;s.sources=[]
        XCTAssertTrue(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s).isEmpty)
    }
    func testUnknownInventoryNeverChoosesCanonicalCopy() throws {
        let(r,base,_)=fixture();var s=base;s.preferredCopyIDs=[:]
        XCTAssertTrue(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s).isEmpty)
    }
    func testMissingTrackedIDBlocksCleanup() {
        let(r,base,_)=fixture();var s=base;s.unlocatedTrackedIDs=["missing"]
        XCTAssertThrowsError(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s))
    }
    func testBusyTitleWithoutMarkerIsNotOwned() throws {
        let(r,base,_)=fixture();var s=base;s.copies.append(.init(id:"unrelated",marker:"other",value:base.copies[0].value))
        XCTAssertFalse(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s).contains{$0.existingID=="unrelated"})
    }
    func testUpdateMustPrecedeCleanup() throws {
        let(r,base,_)=fixture();var s=base
        s.sources=[.init(key:"source",value:.init(title:"private",start:now+60,end:now+3660))]
        XCTAssertTrue(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s).isEmpty)
    }
    func testStaleDuplicateCanBeRemovedWhenTrackedCopyIsCurrent() throws {
        let (r,base,marker)=fixture(); var s=base
        var old=base.copies[0].value; old.start=old.start-3600; old.end=old.end-3600; old.title="Ocupado"
        s.copies=[base.copies[0],.init(id:"old-copy",marker:marker,value:old)]
        let changes=try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s)
        XCTAssertEqual(changes.map(\.existingID),["old-copy"])
        XCTAssertEqual(changes.first?.before,old)
    }
    func testParticipantDuplicateAndForeignMarkerArePreserved() throws {
        let (r,base,marker)=fixture();var s=base
        s.copies=[base.copies[0],.init(id:"invitation",marker:marker,value:base.copies[0].value,hasParticipants:true),.init(id:"foreign",marker:"workharbor://other/route/key",value:base.copies[0].value)]
        XCTAssertTrue(try CleanupPlanner.candidates(installation:installation,rule:r,snapshot:s).isEmpty)
    }
}
