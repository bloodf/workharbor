import Foundation
import AppKit
import EventKit
import Network
import HarborCore

struct CalendarReview: Identifiable {
    let id = UUID()
    let rule: MirrorRule
    let installation: UUID
    let interval: DateInterval
    let snapshot: SyncSnapshot
    var changes: [PlannedChange]
    let createdAt = Date()
    let demo: Bool
    var routes: [MirrorRule] = []
    var cleanupOnly=false
    var unresolvedCopies: [OwnedEvent] {
        Reconciler.unmatchedCopies(installation: installation, rule: rule, snapshot: snapshot)
    }
}

@MainActor
final class CalendarService {
    private let store = EKEventStore()
    private let network = NWPathMonitor()
    private let inventoryURL: URL
    private let pendingWriteURL: URL
    private var inventory: [String: String] = [:] // copy marker -> local event ID, no event content
    private var inventoryError = false
    private var routeGraph: [MirrorRule] = []
    func configureRoutes(_ routes: [MirrorRule]) { routeGraph = routes }
    var fullAccess: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }
    init(directory: URL) {
        inventoryURL = directory.appendingPathComponent("copies.json")
        pendingWriteURL = directory.appendingPathComponent("pending-write.json")
        network.start(queue: DispatchQueue(label: "local.workharbor.reachability"))
        if FileManager.default.fileExists(atPath: inventoryURL.path) {
            do { inventory = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: inventoryURL)) }
            catch { inventoryError = true }
        }
    }
    func requestAccess() async throws {
        guard try await store.requestFullAccessToEvents() else { throw HarborError.invalid("Permissão de calendário não concedida. Nenhuma leitura ou escrita realizada.") }
    }
    func calendars() throws -> [CalendarInfo] {
        guard fullAccess else { throw HarborError.invalid("Solicite acesso ao Calendário. A autorização do app Calendário não se transfere para este aplicativo.") }
        return store.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, name: "\($0.source.title) · \($0.title)", writable: $0.allowsContentModifications)
        }.sorted { $0.name < $1.name }
    }
    func upcoming(calendarIDs:[String],showAll:Bool)->[AgendaEvent] {
        guard fullAccess else { return [] }
        let now=Date(), end=Calendar.current.date(byAdding:.day,value:7,to:now)!
        let selected=store.calendars(for:.event).filter { showAll || calendarIDs.contains($0.calendarIdentifier) }
        guard !selected.isEmpty else { return [] }
        let predicate=store.predicateForEvents(withStart:now,end:end,calendars:selected)
        return store.events(matching:predicate).filter { event in
            event.endDate > now && event.status != .canceled
        }.sorted { $0.startDate < $1.startDate }.prefix(80).map { event in
            let color=NSColor(cgColor:event.calendar.cgColor)?.usingColorSpace(.deviceRGB) ?? .systemBlue
            return AgendaEvent(id:(event.eventIdentifier ?? UUID().uuidString)+"-"+String(event.startDate.timeIntervalSince1970),title:event.title ?? "Untitled",calendarName:event.calendar.title,start:event.startDate,end:event.endDate,allDay:event.isAllDay,red:Double(color.redComponent),green:Double(color.greenComponent),blue:Double(color.blueComponent))
        }
    }
    private func value(_ event: EKEvent) -> EventValue {
        EventValue(title: event.title ?? "Sem título", start: event.startDate, end: event.endDate, allDay: event.isAllDay,
                   timeZone: event.timeZone?.identifier, notes: event.notes, location: event.location)
    }
    private func snapshot(rule: MirrorRule, installation: UUID, interval: DateInterval) throws -> SyncSnapshot {
        guard !inventoryError else { throw HarborError.invalid("Inventário de cópias ilegível. Escrita bloqueada; preserve copies.json para recuperação.") }
        try Reconciler.validate([rule], calendars: calendars())
        guard let source = store.calendar(withIdentifier: rule.sourceID), let destination = store.calendar(withIdentifier: rule.destinationID) else {
            throw HarborError.invalid("Calendário removido. Escolha novamente origem e destino.")
        }
        // Validate ancestor ownership even when an upstream automatic route is paused.
        // A stripped/missing marker must not become a fresh native event downstream.
        for upstream in routeGraph where upstream.destinationID == rule.sourceID {
            let parent = try snapshot(rule: upstream, installation: installation, interval: interval)
            guard parent.unlocatedTrackedIDs.isEmpty else { throw HarborError.invalid("Uma rota de origem tem cópias rastreadas não localizadas. Encadeamento suspenso para evitar duplicatas.") }
        }
        let events = store.events(matching: store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: [source]))
        let sources: [SourceEvent] = try events.filter { $0.status != .canceled }.map { event in
            guard event.startDate != nil, event.endDate != nil else { throw HarborError.invalid("Evento incompleto; tente atualizar o Calendário.") }
            // occurrenceDate remains the recurrence anchor when a single occurrence moves.
            let anchor = (event.hasRecurrenceRules || event.isDetached) ? (event.occurrenceDate ?? event.startDate) : nil
            let itemID = event.calendarItemExternalIdentifier ?? event.calendarItemIdentifier
            for (trackedMarker, trackedID) in inventory where trackedID == event.eventIdentifier {
                guard event.url?.absoluteString == trackedMarker else { throw HarborError.invalid("Uma cópia de origem perdeu seu marcador. Encadeamento bloqueado; ela não será tratada como evento novo.") }
            }
            let marker = event.url?.scheme == "workharbor" ? event.url?.absoluteString : nil
            let upstream = routeGraph.first { $0.destinationID == rule.sourceID && $0.mode == .details && marker?.hasPrefix(Reconciler.prefix(installation: installation, rule: $0)) == true }
            let canForward = marker.map { inventory[$0] == event.eventIdentifier } == true && upstream != nil && !event.hasAttendees && event.organizer == nil && !event.hasRecurrenceRules
            let key = canForward ? marker! : OccurrenceIdentity.key(itemID: itemID, occurrence: anchor, allDay: event.isAllDay)
            var payload = value(event)
            if let url = event.url, url.scheme != "workharbor" {
                payload.notes = [payload.notes, "URL: " + url.absoluteString].compactMap { $0 }.joined(separator: "\n")
            }
            return SourceEvent(key: key, value: payload, isMirror: marker != nil && !canForward)
        }
        let prefix = Reconciler.prefix(installation: installation, rule: rule)
        // Query the window and all known inventory entries. Absence never proves cancellation.
        let candidates = store.events(matching: store.predicateForEvents(withStart: interval.start.addingTimeInterval(-86400), end: interval.end.addingTimeInterval(86400), calendars: [destination]))
        var byID: [String: EKEvent] = [:]
        for event in candidates { if let id = event.eventIdentifier { byID[id] = event } }
        var unlocated: [String] = []
        var recoveredInventory = inventory
        let recoveryCandidates = candidates.compactMap { event -> OwnedEvent? in
            guard event.calendar.calendarIdentifier == rule.destinationID, let id = event.eventIdentifier, let marker = event.url?.absoluteString else { return nil }
            return OwnedEvent(id: id, marker: marker, value: value(event), hasParticipants: event.hasAttendees || event.organizer != nil || event.hasRecurrenceRules)
        }
        for (marker, id) in inventory where marker.hasPrefix(prefix) {
            if let event = store.event(withIdentifier: id) {
                try TrackedCopyGuard.validate(expectedMarker: marker, actualMarker: event.url?.absoluteString,
                                              expectedCalendar: rule.destinationID, actualCalendar: event.calendar.calendarIdentifier)
                byID[id] = event
            } else if let replacement = try TrackedCopyRecovery.replacement(marker: marker, candidates: recoveryCandidates) {
                recoveredInventory[marker] = replacement
            } else { unlocated.append(id) }
        }
        if recoveredInventory != inventory {
            // Rebind only previously tracked, exact, unique markers. Never clear an uncertain write journal.
            do {
                try JSONEncoder().encode(recoveredInventory).write(to: inventoryURL, options: .atomic)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: inventoryURL.path)
                inventory = recoveredInventory
            } catch { inventoryError = true; throw HarborError.invalid("Não foi possível salvar a identidade recuperada. Escritas continuam bloqueadas.") }
        }
        let copies = byID.values.compactMap { event -> OwnedEvent? in
            guard let marker = event.url?.absoluteString, marker.hasPrefix(prefix), let id = event.eventIdentifier else { return nil }
            return OwnedEvent(id: id, marker: marker, value: value(event), hasParticipants: event.hasAttendees || event.organizer != nil || event.hasRecurrenceRules)
        }.sorted { $0.id < $1.id }
        guard fullAccess else { throw HarborError.invalid("Permissão revogada durante a leitura.") }
        return SyncSnapshot(sources: sources.sorted { $0.key < $1.key }, copies: copies, unlocatedTrackedIDs: unlocated, preferredCopyIDs:inventory.filter { $0.key.hasPrefix(prefix) })
    }
    func preview(rule: MirrorRule, installation: UUID) throws -> CalendarReview {
        let now = Date()
        let interval = DateInterval(start: now.addingTimeInterval(-30 * 86400), end: now.addingTimeInterval(180 * 86400))
        let snapshot = try snapshot(rule: rule, installation: installation, interval: interval)
        var review = CalendarReview(rule: rule, installation: installation, interval: interval, snapshot: snapshot,
                              changes: try Reconciler.plan(installation: installation, rule: rule, snapshot: snapshot), demo: false)
        review.routes = routeGraph
        return review
    }
    func previewCleanup(rule:MirrorRule,installation:UUID) throws -> CalendarReview {
        var review=try preview(rule:rule,installation:installation)
        review.changes=try CleanupPlanner.candidates(installation:installation,rule:rule,snapshot:review.snapshot)
        review.cleanupOnly=true
        return review
    }
    func apply(_ review: CalendarReview, confirmed: Bool, includeDeletions: Bool, automatic: Bool = false) throws -> Int {
        guard review.routes == routeGraph else { throw HarborError.invalid("As rotas mudaram desde a prévia. Revise novamente.") }
        guard confirmed, !review.demo else { throw HarborError.invalid("Prévia sintética ou sem confirmação: gravação bloqueada.") }
        guard Date().timeIntervalSince(review.createdAt) < 300 else { throw HarborError.invalid("Prévia expirada. Gere uma nova revisão.") }
        let fresh = try snapshot(rule: review.rule, installation: review.installation, interval: review.interval)
        try ReviewGuard.validate(confirmed: confirmed, demo: review.demo, fullAccess: fullAccess, networkAvailable: network.currentPath.status == .satisfied, createdAt: review.createdAt, now: Date(), reviewed: review.snapshot, current: fresh)
        guard let destination = store.calendar(withIdentifier: review.rule.destinationID), destination.allowsContentModifications else {
            throw HarborError.invalid("Destino indisponível ou sem permissão de escrita.")
        }
        if review.cleanupOnly {
            guard !automatic else { throw HarborError.invalid("A limpeza exige seleção e confirmação explícitas.") }
            let allowed=try CleanupPlanner.candidates(installation:review.installation,rule:review.rule,snapshot:fresh)
            guard review.changes.allSatisfy({ allowed.contains($0) }) else { throw HarborError.invalid("A prévia de limpeza mudou. Revise novamente.") }
        }
        let selected: [PlannedChange]
        if automatic {
            guard fresh.copies.allSatisfy({ inventory[$0.marker] == $0.id }) else {
                throw HarborError.invalid("Cópia identificada mas não comprovada pelo inventário. Automático suspenso; revise no Calendário.")
            }
            selected = try AutomaticSyncPolicy.changes(installation: review.installation, rule: review.rule, snapshot: fresh)
        } else {
            selected = review.changes.filter { includeDeletions || $0.kind != .delete }
        }
        guard !selected.isEmpty else { return 0 }
        guard !FileManager.default.fileExists(atPath: pendingWriteURL.path) else {
            throw HarborError.invalid("Existe uma gravação anterior com resultado não reconciliado. Novas gravações estão suspensas, inclusive após reiniciar. Preserve pending-write.json e confirme as cópias no calendário de destino antes da recuperação; não repita o lote.")
        }
        // Persist intent before the first mutation. A crash or uncertain commit must
        // not be retried by the timer against a temporarily empty local snapshot.
        let intent = PendingWriteIntent(ruleID: review.rule.id, destinationID: review.rule.destinationID,
                                        markers: selected.map(\.marker), existingIDs: selected.compactMap(\.existingID))
        try PendingWriteJournal(file: pendingWriteURL).begin(intent)
        var saved: [(String, EKEvent)] = []
        var deleted: [(marker: String, id: String)] = []
        do {
            for change in selected {
                let event: EKEvent
                if let id = change.existingID {
                    guard let existing = store.event(withIdentifier: id), existing.calendar.calendarIdentifier == review.rule.destinationID,
                          existing.url?.absoluteString == change.marker, !existing.hasAttendees, existing.organizer == nil,
                          !existing.hasRecurrenceRules else { throw HarborError.invalid("A cópia mudou ou contém participantes. Gravação cancelada.") }
                    event = existing
                } else {
                    event = EKEvent(eventStore: store)
                    event.calendar = destination
                }
                if change.kind == .delete {
                    try store.remove(event, span: .thisEvent, commit: false)
                    deleted.append((change.marker, event.eventIdentifier))
                } else if let after = change.after {
                    event.title = after.title; event.startDate = after.start; event.endDate = after.end
                    event.isAllDay = after.allDay; event.timeZone = after.timeZone.flatMap(TimeZone.init(identifier:))
                    event.notes = after.notes; event.location = after.location
                    event.url = URL(string: change.marker)
                    event.alarms = nil
                    event.availability = .busy
                    try store.save(event, span: .thisEvent, commit: false)
                    saved.append((change.marker, event))
                }
            }
            guard fullAccess else { throw HarborError.invalid("Acesso revogado antes da gravação.") }
            try store.commit()
        } catch {
            store.reset()
            throw HarborError.invalid("EventKit não confirmou o lote. Refaça a prévia antes de tentar novamente; não foi declarado sucesso.")
        }
        let savedIDs=Dictionary(grouping:saved.compactMap { marker,event -> (String,String)? in
            guard let id=event.eventIdentifier else { return nil }; return (marker,id)
        },by: { $0.0 }).mapValues { $0.map { $0.1 } }
        inventory=CopyInventory.reconcile(existing:inventory,saved:savedIDs,copies:fresh.copies,deletedIDs:Set(deleted.map(\.id)))
        do {
            try FileManager.default.createDirectory(at: inventoryURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            try JSONEncoder().encode(inventory).write(to: inventoryURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: inventoryURL.path)
        } catch {
            inventoryError = true
            throw HarborError.invalid("EventKit confirmou gravação local, mas o inventário não foi salvo. Pare e preserve os dados antes de repetir.")
        }
        // Only a confirmed local commit plus durable inventory resolves this attempt.
        try PendingWriteJournal(file: pendingWriteURL).complete(attemptID: intent.id)
        return selected.count
    }
    static func demo() throws -> CalendarReview {
        var rule = MirrorRule(); rule.sourceID = "sintetico-pessoal"; rule.destinationID = "sintetico-trabalho"
        let now = Date(); let installation = UUID()
        let source = SourceEvent(key: "demo", value: EventValue(title: "Consulta pessoal (fictícia)", start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200), notes: "Detalhes privados fictícios", location: "Local fictício"))
        let snapshot = SyncSnapshot(sources: [source], copies: [])
        return CalendarReview(rule: rule, installation: installation, interval: DateInterval(start: now, duration: 86400), snapshot: snapshot,
                              changes: try Reconciler.plan(installation: installation, rule: rule, snapshot: snapshot), demo: true)
    }
}
