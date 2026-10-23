import Foundation
import CryptoKit

public struct CalendarInfo: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let writable: Bool
    public init(id: String, name: String, writable: Bool) { self.id = id; self.name = name; self.writable = writable }
}
public struct EventValue: Codable, Equatable, Sendable {
    public var title: String
    public var start: Date
    public var end: Date
    public var allDay: Bool
    public var timeZone: String?
    public var notes: String?
    public var location: String?
    public init(title: String, start: Date, end: Date, allDay: Bool = false, timeZone: String? = nil, notes: String? = nil, location: String? = nil) {
        self.title = title; self.start = start; self.end = end; self.allDay = allDay; self.timeZone = timeZone; self.notes = notes; self.location = location
    }
}
public struct SourceEvent: Equatable, Sendable {
    public let key: String
    public let value: EventValue
    public let isMirror: Bool
    public init(key: String, value: EventValue, isMirror: Bool = false) { self.key = key; self.value = value; self.isMirror = isMirror }
}
public struct OwnedEvent: Equatable, Sendable {
    public let id: String
    public let marker: String
    public let value: EventValue
    public let hasParticipants: Bool
    public init(id: String, marker: String, value: EventValue, hasParticipants: Bool = false) { self.id = id; self.marker = marker; self.value = value; self.hasParticipants = hasParticipants }
}
public enum ChangeKind: String, Sendable { case create = "Criar", update = "Atualizar", delete = "Excluir cópia" }
public struct PlannedChange: Identifiable, Equatable, Sendable {
    public var id: String { marker + kind.rawValue + (existingID ?? "") }
    public let kind: ChangeKind
    public let marker: String
    public let existingID: String?
    public let before: EventValue?
    public let after: EventValue?
}
public struct SyncSnapshot: Equatable, Sendable {
    public var sources: [SourceEvent]
    public var copies: [OwnedEvent]
    public var complete: Bool
    public var preferredCopyIDs: [String:String]
    public var unlocatedTrackedIDs: [String]
    public init(sources: [SourceEvent], copies: [OwnedEvent], complete: Bool = true, unlocatedTrackedIDs: [String] = [], preferredCopyIDs: [String:String] = [:]) { self.sources = sources; self.copies = copies; self.complete = complete; self.unlocatedTrackedIDs = unlocatedTrackedIDs.sorted();self.preferredCopyIDs=preferredCopyIDs }
}
public enum Reconciler {
    public static func prefix(installation: UUID, rule: MirrorRule) -> String {
        "workharbor://" + installation.uuidString.lowercased() + "/" + rule.id.uuidString.lowercased() + "/"
    }
    public static func marker(installation: UUID, rule: MirrorRule, sourceKey: String) -> String {
        prefix(installation: installation, rule: rule) + SHA256.hash(data: Data(sourceKey.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    public static func validate(_ rules: [MirrorRule], calendars: [CalendarInfo]) throws {
        for rule in rules {
            guard !rule.sourceID.isEmpty, rule.sourceID != rule.destinationID,
                  calendars.contains(where: { $0.id == rule.sourceID }),
                  calendars.contains(where: { $0.id == rule.destinationID && $0.writable }),
                  (0...240).contains(rule.beforeMinutes), (0...240).contains(rule.afterMinutes) else {
                throw HarborError.invalid("Escolha origem existente e destino diferente, gravável; buffers entre 0 e 240 minutos.")
            }
        }
        _ = try RouteGraph.ordered(rules)
    }
    public static func transformed(_ value: EventValue, by rule: MirrorRule) -> EventValue {
        guard rule.mode == .busy else { return value }
        return EventValue(title: "Busy", start: value.start.addingTimeInterval(value.allDay ? 0 : -Double(rule.beforeMinutes) * 60),
                          end: value.end.addingTimeInterval(value.allDay ? 0 : Double(rule.afterMinutes) * 60),
                          allDay: value.allDay, timeZone: value.timeZone)
    }
    // A local EventKit absence is not evidence of remote cancellation.
    public static func unmatchedCopies(installation: UUID, rule: MirrorRule, snapshot: SyncSnapshot) -> [OwnedEvent] {
        let routePrefix = prefix(installation: installation, rule: rule)
        let desired = Set(snapshot.sources.filter { !$0.isMirror }.map {
            marker(installation: installation, rule: rule, sourceKey: $0.key)
        })
        return snapshot.copies.filter { $0.marker.hasPrefix(routePrefix) && !desired.contains($0.marker) }
            .sorted { $0.id < $1.id }
    }
    public static func plan(installation: UUID, rule: MirrorRule, snapshot: SyncSnapshot) throws -> [PlannedChange] {
        guard snapshot.complete else { throw HarborError.invalid("Leitura incompleta. Nenhuma alteração será proposta.") }
        let prefix = prefix(installation: installation, rule: rule)
        let copies = snapshot.copies.filter { $0.marker.hasPrefix(prefix) }
        guard !copies.contains(where: \.hasParticipants) else {
            throw HarborError.invalid("Uma cópia possui participantes/organizador. Operação bloqueada para evitar convites.")
        }
        let originals = snapshot.sources.filter { !$0.isMirror }
        guard Set(originals.map(\.key)).count == originals.count else {
            throw HarborError.invalid("Identidade ambígua de ocorrência. Prévia bloqueada.")
        }
        var desired: [String: EventValue] = [:]
        for source in originals {
            guard source.value.end > source.value.start else { throw HarborError.invalid("Evento com intervalo inválido.") }
            desired[marker(installation: installation, rule: rule, sourceKey: source.key)] = transformed(source.value, by: rule)
        }
        let groups = Dictionary(grouping: copies, by: \.marker)
        var changes: [PlannedChange] = []
        for token in desired.keys.sorted() {
            let value = desired[token]!
            let preferred=snapshot.preferredCopyIDs[token]
            let existing = (groups[token] ?? []).sorted { a,b in
                if a.id==preferred { return b.id != preferred };if b.id==preferred { return false };return a.id < b.id
            }
            if let first = existing.first {
                if first.value != value { changes.append(.init(kind: .update, marker: token, existingID: first.id, before: first.value, after: value)) }
                for duplicate in existing.dropFirst() {
                    // Redaction must not depend on the optional deletion checkbox.
                    // Redact first; a later preview can offer deletion once it is clean.
                    if rule.mode == .busy && duplicate.value != value {
                        changes.append(.init(kind: .update, marker: token, existingID: duplicate.id, before: duplicate.value, after: value))
                    } else {
                        changes.append(.init(kind: .delete, marker: token, existingID: duplicate.id, before: duplicate.value, after: nil))
                    }
                }
            } else { changes.append(.init(kind: .create, marker: token, existingID: nil, before: nil, after: value)) }
        }
        for copy in copies.sorted(by: { $0.id < $1.id }) where desired[copy.marker] == nil {
            // Preserve the copy and its existing interval. In busy mode, redact
            // known copies even outside the source horizon, without adding buffers twice.
            if rule.mode == .busy {
                var redacted = copy.value
                redacted.title = "Busy"; redacted.notes = nil; redacted.location = nil
                if redacted != copy.value {
                    changes.append(.init(kind: .update, marker: copy.marker, existingID: copy.id, before: copy.value, after: redacted))
                }
            }
        }
        return changes
    }
}
