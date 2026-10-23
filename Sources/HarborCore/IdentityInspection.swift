import Foundation

/// Metadata only. No event contents are needed to diagnose copy ownership.
public struct CopyIdentityObservation: Equatable, Sendable {
    public var id: String
    public var marker: String?
    public var calendarID: String
    public var unsafe: Bool
    public init(id: String, marker: String?, calendarID: String, unsafe: Bool = false) {
        self.id=id; self.marker=marker; self.calendarID=calendarID; self.unsafe=unsafe
    }
}
public enum CopyIdentityState: String, Equatable, Sendable {
    case located, recoverable, missing, mismatch, ambiguous, unsafe
}
public struct CopyIdentityFinding: Equatable, Sendable, Identifiable {
    public var marker: String
    public var previousID: String
    public var replacementID: String?
    public var state: CopyIdentityState
    public var id: String { marker }
}
public enum IdentityInspection {
    public static func validateReview(createdAt: Date, now: Date) throws {
        guard now >= createdAt, now.timeIntervalSince(createdAt) < 300 else {
            throw HarborError.invalid("Inspection expired or inventory changed. Inspect again.")
        }
    }
    public static func chunks(in interval: DateInterval, calendar: Calendar = Calendar(identifier: .gregorian)) throws -> [DateInterval] {
        guard interval.start.timeIntervalSinceReferenceDate.isFinite, interval.end.timeIntervalSinceReferenceDate.isFinite,
              interval.duration > 0, interval.duration < 1465 * 86400 else { throw HarborError.invalid("Invalid diagnostic date window.") }
        var chunks: [DateInterval] = []
        var cursor = interval.start
        while cursor < interval.end {
            guard let next = calendar.date(byAdding: .year, value: 1, to: cursor), next > cursor else { throw HarborError.invalid("Invalid diagnostic date window.") }
            let end = min(next, interval.end)
            chunks.append(DateInterval(start: cursor, end: end)); cursor = end
        }
        return chunks
    }
    public static func inspect(expected: [String:String], destinationID: String,
                               direct: [String:CopyIdentityObservation], searched: [CopyIdentityObservation]) -> [CopyIdentityFinding] {
        expected.keys.sorted().map { marker in
            let previousID=expected[marker]!
            func finding(_ state: CopyIdentityState, _ replacement: String? = nil) -> CopyIdentityFinding {
                CopyIdentityFinding(marker:marker, previousID:previousID,replacementID:replacement,state:state)
            }
            let matches=searched.filter { $0.calendarID == destinationID && $0.marker == marker }
            if let observed=direct[previousID] {
                guard observed.id == previousID, observed.calendarID == destinationID, observed.marker == marker else {return finding(.mismatch)}
                guard matches.allSatisfy({!$0.id.isEmpty}) else {return finding(.unsafe)}
                guard Set(matches.map(\.id).filter {$0 != previousID}).isEmpty else {return finding(.ambiguous)}
                return finding(observed.unsafe || matches.contains(where: \.unsafe) ? .unsafe : .located)
            }
            guard matches.allSatisfy({!$0.id.isEmpty}) else {return finding(.unsafe)}
            let ids=Set(matches.map(\.id))
            guard !ids.isEmpty else {return finding(.missing)}
            guard ids.count == 1 else {return finding(.ambiguous)}
            guard matches.allSatisfy({!$0.unsafe}) else {return finding(.unsafe)}
            return finding(.recoverable,ids.first!)
        }
    }
    public static func repairedInventory(original:[String:String], reviewed:[CopyIdentityFinding],
                                        current:[CopyIdentityFinding], selected:Set<String>, confirmed:Bool) throws -> [String:String] {
        guard confirmed, !selected.isEmpty, reviewed == current else {throw HarborError.invalid("Identity inspection changed or was not confirmed.")}
        var result=original
        for marker in selected {
            guard let row=current.first(where:{$0.marker == marker}), row.state == .recoverable,
                  original[marker] == row.previousID, let replacement=row.replacementID, !replacement.isEmpty else {
                throw HarborError.invalid("Only exact, unique, safe identities may be reconnected.")
            }
            result[marker]=replacement
        }
        return result
    }
}
