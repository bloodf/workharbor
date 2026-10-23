import Foundation

public enum MirrorMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case details = "Detalhes → pessoal", busy = "Ocupado → trabalho"
    // Preserve the persisted value from earlier releases; presentation is independent.
    public var displayName: String { self == .busy ? "Busy" : "Full details" }
    public var id: String { rawValue }
}
public struct MirrorRule: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var sourceID = ""
    public var destinationID = ""
    public var mode: MirrorMode = .busy
    public var beforeMinutes = 15
    public var afterMinutes = 15
    public var automaticConsent: AutomaticRouteConsent? = nil
    public init() {}
}
public struct AppSettings: Codable, Equatable, Sendable {
    public var installationID = UUID()
    public var rules: [MirrorRule] = []
    public var language = "system"
    public var agendaCalendarIDs: [String] = []
    public var showAllCalendars = true
    public init() {}
    enum CodingKeys:String,CodingKey { case installationID,rules,language,agendaCalendarIDs,showAllCalendars }
    public init(from decoder:Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        installationID=try c.decode(UUID.self,forKey:.installationID)
        rules=try c.decodeIfPresent([MirrorRule].self,forKey:.rules) ?? []
        language=try c.decodeIfPresent(String.self,forKey:.language) ?? "system"
        showAllCalendars=try c.decodeIfPresent(Bool.self,forKey:.showAllCalendars) ?? true
        agendaCalendarIDs=try c.decodeIfPresent([String].self,forKey:.agendaCalendarIDs) ?? []
    }
}
public enum HarborError: Error, LocalizedError, Equatable {
    case invalid(String)
    public var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
}
public struct SettingsStore {
    public let file: URL
    public init(file: URL) { self.file = file }
    public func load() throws -> AppSettings {
        guard FileManager.default.fileExists(atPath: file.path) else { return AppSettings() }
        return try JSONDecoder().decode(AppSettings.self, from: Data(contentsOf: file))
    }
    public func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if FileManager.default.fileExists(atPath:file.path) {
            let backup=file.deletingLastPathComponent().appendingPathComponent("settings-before-calendar-only.json")
            if !FileManager.default.fileExists(atPath:backup.path) { try FileManager.default.copyItem(at:file,to:backup) }
        }
        let encoded=try JSONEncoder().encode(settings)
        var merged:[String:Any]=[:]
        if FileManager.default.fileExists(atPath:file.path) {
            merged=(try JSONSerialization.jsonObject(with:Data(contentsOf:file))) as? [String:Any] ?? [:]
        }
        let current=(try JSONSerialization.jsonObject(with:encoded)) as! [String:Any]
        for (key,value) in current { merged[key]=value }
        let data=try JSONSerialization.data(withJSONObject:merged,options:[.sortedKeys])
        try data.write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
}
