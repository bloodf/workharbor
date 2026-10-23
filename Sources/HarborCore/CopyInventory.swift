import Foundation
public enum CopyInventory {
    // Updating a secondary copy must not replace the tracked canonical identity.
    public static func reconcile(existing:[String:String], saved:[String:[String]], copies:[OwnedEvent], deletedIDs:Set<String>) -> [String:String] {
        var result=existing.filter { !deletedIDs.contains($0.value) }
        for marker in saved.keys.sorted() where result[marker] == nil {
            result[marker]=saved[marker]?.filter { !deletedIDs.contains($0) }.sorted().first
        }
        for copy in copies.sorted(by: { $0.id < $1.id }) where !deletedIDs.contains(copy.id) && result[copy.marker] == nil {
            result[copy.marker]=copy.id
        }
        return result
    }
}
