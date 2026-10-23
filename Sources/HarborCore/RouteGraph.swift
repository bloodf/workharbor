import Foundation

public enum RouteGraph {
    public static func ordered(_ rules: [MirrorRule]) throws -> [MirrorRule] {
        let busyDestinations = Set(rules.filter { $0.mode == .busy }.map(\.destinationID))
        guard !rules.contains(where: { busyDestinations.contains($0.sourceID) }) else {
            throw HarborError.invalid("Um calendário que recebe apenas Busy não pode alimentar outra rota. Use o calendário pessoal como origem.")
        }
        let outgoing = Dictionary(grouping: rules, by: \.sourceID)
        let nodes = Set(rules.flatMap { [$0.sourceID, $0.destinationID] })
        var orderedNodes: [String] = [], visited: Set<String> = [], active: Set<String> = []
        func visit(_ node: String) throws {
            if active.contains(node) { throw HarborError.invalid("Estas rotas formam um ciclo. Mantenha o fluxo em uma única direção.") }
            guard !visited.contains(node) else { return }
            active.insert(node)
            for edge in outgoing[node] ?? [] { try visit(edge.destinationID) }
            active.remove(node); visited.insert(node); orderedNodes.append(node)
        }
        for node in nodes.sorted() { try visit(node) }
        // Reject converging paths that could deliver the same personal event twice.
        for origin in nodes {
            var counts: [String: Int] = [:]
            func countPaths(_ node: String) throws {
                for edge in outgoing[node] ?? [] {
                    counts[edge.destinationID, default: 0] += 1
                    guard counts[edge.destinationID, default: 0] <= 1 else {
                        throw HarborError.invalid("Há mais de um caminho para copiar os mesmos eventos a um destino. Remova a rota redundante para evitar duplicatas.")
                    }
                    try countPaths(edge.destinationID)
                }
            }
            try countPaths(origin)
        }
        let ranks = Dictionary(uniqueKeysWithValues: orderedNodes.reversed().enumerated().map { ($0.element, $0.offset) })
        return rules.sorted { (ranks[$0.sourceID] ?? 0) < (ranks[$1.sourceID] ?? 0) }
    }
}
public enum TrackedCopyRecovery {
    public static func replacement(marker: String, candidates: [OwnedEvent]) throws -> String? {
        let exact = candidates.filter { $0.marker == marker }
        guard exact.count <= 1 else { throw HarborError.invalid("Mais de uma cópia tem o marcador rastreado. Revise antes de continuar.") }
        guard let candidate = exact.first else { return nil }
        guard !candidate.id.isEmpty, !candidate.hasParticipants else { throw HarborError.invalid("A cópia encontrada tem identidade ou participantes incompatíveis. Revisão necessária.") }
        return candidate.id
    }
}
