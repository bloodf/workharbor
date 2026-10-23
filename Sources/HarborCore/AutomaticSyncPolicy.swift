import Foundation

/// Consent is bound to the exact route and payload policy, never inherited by a changed route.
public struct AutomaticRouteConsent: Codable, Equatable, Sendable {
    public let ruleID: UUID
    public let sourceID: String
    public let destinationID: String
    public let mode: MirrorMode
    public let beforeMinutes: Int
    public let afterMinutes: Int
    public let grantedAt: Date
    public init(rule: MirrorRule, grantedAt: Date = Date()) {
        ruleID = rule.id; sourceID = rule.sourceID; destinationID = rule.destinationID
        mode = rule.mode; beforeMinutes = rule.beforeMinutes; afterMinutes = rule.afterMinutes
        self.grantedAt = grantedAt
    }
    public func covers(_ rule: MirrorRule) -> Bool {
        ruleID == rule.id && sourceID == rule.sourceID && destinationID == rule.destinationID &&
        mode == rule.mode && beforeMinutes == rule.beforeMinutes && afterMinutes == rule.afterMinutes
    }
}
public enum AutomaticSyncPolicy {
    public static func isAuthorized(_ rule: MirrorRule) -> Bool {
        rule.automaticConsent?.covers(rule) == true
    }
    public static func changes(installation: UUID, rule: MirrorRule, snapshot: SyncSnapshot) throws -> [PlannedChange] {
        guard isAuthorized(rule) else { throw HarborError.invalid("Esta rota não possui autorização automática válida.") }
        guard snapshot.unlocatedTrackedIDs.isEmpty else {
            throw HarborError.invalid("Há cópias rastreadas não localizadas. Sincronização automática suspensa para evitar duplicatas.")
        }
        // An absent source is unresolved, not deleted. No destructive cleanup in background.
        return try Reconciler.plan(installation: installation, rule: rule, snapshot: snapshot).filter { $0.kind != .delete }
    }
}
