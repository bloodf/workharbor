public enum StatusItemMouseButton: Sendable { case primary, secondary, other }
public enum StatusItemIntent: Equatable, Sendable { case toggleAgenda, quickOptions, ignore }
public enum StatusQuickAction: String, CaseIterable, Equatable, Sendable {
    case agenda, settings, refresh, quit
}
public enum StatusMenuPolicy {
    public static func intent(button: StatusItemMouseButton, controlModified: Bool = false) -> StatusItemIntent {
        switch button {
        case .secondary: return .quickOptions
        case .primary: return controlModified ? .quickOptions : .toggleAgenda
        case .other: return .ignore
        }
    }
}
/// A menu opening or cancellation is not an action. A selection is dispatched only after tracking ends.
public struct StatusMenuSession: Sendable {
    public private(set) var isOpen = false
    private var canRefresh = false
    private var selected: StatusQuickAction?
    public init() {}
    @discardableResult public mutating func begin(canRefresh: Bool) -> Bool {
        guard !isOpen else { return false }
        self.canRefresh = canRefresh; selected = nil; isOpen = true
        return true
    }
    public mutating func select(_ action: StatusQuickAction) {
        guard isOpen, selected == nil, action != .refresh || canRefresh else { return }
        selected = action
    }
    public mutating func finish() -> StatusQuickAction? {
        guard isOpen else { return nil }
        defer { isOpen = false; selected = nil }
        return selected
    }
}
