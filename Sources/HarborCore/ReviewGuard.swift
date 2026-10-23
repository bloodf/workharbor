import Foundation

public enum ReviewGuard {
    public static func validate(confirmed: Bool, demo: Bool, fullAccess: Bool, networkAvailable: Bool = true, createdAt: Date, now: Date,
                                reviewed: SyncSnapshot, current: SyncSnapshot) throws {
        guard confirmed, !demo else { throw HarborError.invalid("Prévia sintética ou sem confirmação: gravação bloqueada.") }
        guard networkAvailable else { throw HarborError.invalid("Sem rede disponível. A prévia pode ser consultada, mas a gravação fica bloqueada até reconectar e revisar novamente.") }
        guard fullAccess else { throw HarborError.invalid("Permissão revogada. Nenhuma gravação autorizada.") }
        guard now >= createdAt, now.timeIntervalSince(createdAt) < 300 else { throw HarborError.invalid("Prévia expirada. Gere uma nova revisão.") }
        // Missing local IDs are not proof of deletion. This guard applies to
        // manual reviews too, before any EventKit mutation or pending-write intent.
        guard reviewed.unlocatedTrackedIDs.isEmpty, current.unlocatedTrackedIDs.isEmpty else {
            throw HarborError.invalid("Cópias rastreadas não localizadas. Gravação manual e automática bloqueada até reconciliar as identidades.")
        }
        guard reviewed.complete, current.complete, reviewed == current else { throw HarborError.invalid("Calendário mudou desde a prévia. Revise novamente.") }
    }
}
public enum OccurrenceIdentity {
    public static func key(itemID: String, occurrence: Date?, allDay: Bool, calendar: Calendar = .current) -> String {
        guard let occurrence else { return itemID }
        if allDay {
            let day = calendar.dateComponents([.year, .month, .day], from: occurrence)
            return "\(itemID)|day:\(day.year!)-\(day.month!)-\(day.day!)"
        }
        return itemID + "|" + String(occurrence.timeIntervalSinceReferenceDate)
    }
}

public enum TrackedCopyGuard {
    public static func validate(expectedMarker: String, actualMarker: String?, expectedCalendar: String, actualCalendar: String) throws {
        guard expectedMarker == actualMarker, expectedCalendar == actualCalendar else {
            throw HarborError.invalid("Uma cópia rastreada perdeu o marcador ou mudou de calendário. Operação bloqueada para evitar duplicatas; revise a cópia no Calendário.")
        }
    }
}
