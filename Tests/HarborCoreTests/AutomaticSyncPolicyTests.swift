import XCTest
@testable import HarborCore

final class AutomaticSyncPolicyTests: XCTestCase {
    func rule() -> MirrorRule { var r = MirrorRule(); r.sourceID = "apple"; r.destinationID = "work"; return r }
    func testDefaultRouteNeverWritesAutomatically() {
        XCTAssertFalse(AutomaticSyncPolicy.isAuthorized(rule()))
    }
    func testConsentCoversExactRoute() {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        XCTAssertTrue(AutomaticSyncPolicy.isAuthorized(r))
    }
    func testChangingAnyDestinationPayloadOrIdentityRevokesConsent() {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        var variants: [MirrorRule] = []
        var a = r; a.id = UUID(); variants.append(a)
        a = r; a.sourceID = "other"; variants.append(a)
        a = r; a.destinationID = "other"; variants.append(a)
        a = r; a.mode = .details; variants.append(a)
        a = r; a.beforeMinutes = 30; variants.append(a)
        a = r; a.afterMinutes = 30; variants.append(a)
        for changed in variants { XCTAssertFalse(AutomaticSyncPolicy.isAuthorized(changed)) }
    }
    func testPauseRevokesConsent() {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        r.automaticConsent = nil; XCTAssertFalse(AutomaticSyncPolicy.isAuthorized(r))
    }
    func testLegacyRuleDecodesWithoutConsent() throws {
        let json = """
        {"id":"11111111-1111-1111-1111-111111111111","sourceID":"apple","destinationID":"work","mode":"Ocupado → trabalho","beforeMinutes":15,"afterMinutes":15}
        """
        let decoded = try JSONDecoder().decode(MirrorRule.self, from: Data(json.utf8))
        XCTAssertNil(decoded.automaticConsent); XCTAssertFalse(AutomaticSyncPolicy.isAuthorized(decoded))
    }
    func testConsentSurvivesRestartWithoutBroadeningScope() throws {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        let copy = try JSONDecoder().decode(MirrorRule.self, from: JSONEncoder().encode(r))
        XCTAssertEqual(copy, r); XCTAssertTrue(AutomaticSyncPolicy.isAuthorized(copy))
    }
    func testUnauthorizedPlannerThrows() {
        XCTAssertThrowsError(try AutomaticSyncPolicy.changes(installation: UUID(), rule: rule(), snapshot: .init(sources: [], copies: [])))
    }
    func testMissingInventoryItemBlocksAutomatic() {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        XCTAssertThrowsError(try AutomaticSyncPolicy.changes(installation: UUID(), rule: r, snapshot: .init(sources: [], copies: [], unlocatedTrackedIDs: ["missing"])))
    }
    func testAutomaticCreatesRedactedCopyAndNeverDeletesDuplicate() throws {
        let installation = UUID(); var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        let source = SourceEvent(key: "1", value: .init(title: "Privado", start: start, end: start + 3600, notes: "segredo", location: "local"))
        let created = try AutomaticSyncPolicy.changes(installation: installation, rule: r, snapshot: .init(sources: [source], copies: []))
        XCTAssertEqual(created.count, 1); XCTAssertEqual(created[0].kind, .create)
        XCTAssertEqual(created[0].after?.title, "Busy"); XCTAssertNil(created[0].after?.notes)
        let copies = ["a", "b"].map { OwnedEvent(id: $0, marker: created[0].marker, value: created[0].after!) }
        XCTAssertTrue(try AutomaticSyncPolicy.changes(installation: installation, rule: r, snapshot: .init(sources: [source], copies: copies)).isEmpty)
        XCTAssertTrue(try AutomaticSyncPolicy.changes(installation: installation, rule: r, snapshot: .init(sources: [], copies: copies)).isEmpty)
    }
    func testIncompleteReadBlocksAutomatic() {
        var r = rule(); r.automaticConsent = AutomaticRouteConsent(rule: r)
        XCTAssertThrowsError(try AutomaticSyncPolicy.changes(installation: UUID(), rule: r, snapshot: .init(sources: [], copies: [], complete: false)))
    }
}
