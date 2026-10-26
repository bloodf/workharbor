import XCTest
@testable import HarborCore
final class StatusMenuPolicyTests: XCTestCase {
    func testPrimaryKeepsAgendaAndSecondaryOpensOptions() {
        XCTAssertEqual(StatusMenuPolicy.intent(button:.primary),.toggleAgenda)
        XCTAssertEqual(StatusMenuPolicy.intent(button:.secondary),.quickOptions)
        XCTAssertEqual(StatusMenuPolicy.intent(button:.secondary,controlModified:true),.quickOptions)
    }
    func testControlClickIsEquivalentSecondaryInput() {
        XCTAssertEqual(StatusMenuPolicy.intent(button:.primary,controlModified:true),.quickOptions)
    }
    func testOtherMouseButtonsAreIgnored() { XCTAssertEqual(StatusMenuPolicy.intent(button:.other),.ignore) }
    func testOpeningAndCancellingNeverDispatchesAction() {
        var session=StatusMenuSession()
        for _ in 0..<100 { XCTAssertTrue(session.begin(canRefresh:true));XCTAssertNil(session.finish()) }
    }
    func testEverySelectionIsDeferredAndDispatchedOnce() {
        for action in StatusQuickAction.allCases {
            var session=StatusMenuSession();XCTAssertTrue(session.begin(canRefresh:true));session.select(action)
            XCTAssertTrue(session.isOpen);XCTAssertEqual(session.finish(),action);XCTAssertNil(session.finish())
        }
    }
    func testUnavailableRefreshAndSelectionOutsideMenuDoNothing() {
        var session=StatusMenuSession();session.select(.quit);XCTAssertNil(session.finish())
        session.begin(canRefresh:false);session.select(.refresh);XCTAssertNil(session.finish())
    }
    func testNestedOpenDoesNotErasePendingSelection() {
        var session=StatusMenuSession();session.begin(canRefresh:true);session.select(.settings)
        XCTAssertFalse(session.begin(canRefresh:false));XCTAssertEqual(session.finish(),.settings)
    }
    func testRepeatedSelectionUsesOnlyFirstActionAndResetDoesNotLeak() {
        var session=StatusMenuSession();session.begin(canRefresh:true);session.select(.agenda);session.select(.quit)
        XCTAssertEqual(session.finish(),.agenda);session.begin(canRefresh:true);XCTAssertNil(session.finish())
    }
}
