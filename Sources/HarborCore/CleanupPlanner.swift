import Foundation
public enum CleanupPlanner {
    public static func candidates(installation:UUID,rule:MirrorRule,snapshot:SyncSnapshot) throws -> [PlannedChange] {
        guard snapshot.complete,snapshot.unlocatedTrackedIDs.isEmpty else { throw HarborError.invalid("Há identidades não localizadas. Limpeza bloqueada até revisão.") }
        let prefix=Reconciler.prefix(installation:installation,rule:rule)
        let originals=snapshot.sources.filter { !$0.isMirror }
        guard Set(originals.map(\.key)).count==originals.count else { throw HarborError.invalid("Origem ambígua. Nenhuma limpeza proposta.") }
        let desired=Dictionary(uniqueKeysWithValues:originals.map { (Reconciler.marker(installation:installation,rule:rule,sourceKey:$0.key),Reconciler.transformed($0.value,by:rule)) })
        let groups=Dictionary(grouping:snapshot.copies.filter { $0.marker.hasPrefix(prefix) },by:\.marker)
        var result:[PlannedChange]=[]
        for marker in groups.keys.sorted() {
            guard let expected=desired[marker],let trackedID=snapshot.preferredCopyIDs[marker],let copies=groups[marker],
                  let current=copies.first(where:{$0.id==trackedID}),current.value==expected,!current.hasParticipants else { continue }
            for copy in copies where copy.id != trackedID && !copy.hasParticipants {
                result.append(.init(kind:.delete,marker:marker,existingID:copy.id,before:copy.value,after:nil))
            }
        }
        return result.sorted { ($0.existingID ?? "") < ($1.existingID ?? "") }
    }
}
