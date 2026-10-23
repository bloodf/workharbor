import Foundation

public struct AppVersion: Equatable, Sendable {
    public let version: String
    public let build: String
    public init(info: [String: Any]) {
        version = Self.nonempty(info["CFBundleShortVersionString"]) ?? "?"
        build = Self.nonempty(info["CFBundleVersion"]) ?? "?"
    }
    private static func nonempty(_ value: Any?) -> String? {
        guard let value = value as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }
}
