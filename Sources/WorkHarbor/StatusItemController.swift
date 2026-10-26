import AppKit
import HarborCore

@MainActor
final class StatusItemController: NSObject {
    let item: NSStatusItem
    let popover = NSPopover()
    private let title: (String) -> String
    private let canRefresh: () -> Bool
    private let openSettings: () -> Void
    private let refresh: () -> Void
    private let quit: () -> Void
    private let presentMenu: (NSMenu, NSStatusBarButton) -> Void
    private var session = StatusMenuSession()
    private var invalidated = false
    private var agendaRequested = false
    private var activationObserver: NSObjectProtocol?

    init(agenda: NSViewController, title: @escaping (String) -> String, canRefresh: @escaping () -> Bool,
         openSettings: @escaping () -> Void, refresh: @escaping () -> Void, quit: @escaping () -> Void,
         presentMenu: ((NSMenu, NSStatusBarButton) -> Void)? = nil) {
        self.title = title; self.canRefresh = canRefresh; self.openSettings = openSettings
        self.refresh = refresh; self.quit = quit
        self.presentMenu = presentMenu ?? { menu, button in
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
        }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        activationObserver = NotificationCenter.default.addObserver(forName:NSApplication.didBecomeActiveNotification,object:NSApp,queue:.main) { [weak self] _ in
            Task { @MainActor in self?.presentRequestedAgenda() }
        }
        popover.behavior = .transient
        popover.contentViewController = agenda
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "WorkHarbor")
            button.image?.isTemplate = true
            button.target = self; button.action = #selector(buttonActivated(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("WorkHarbor")
            updateAccessibility()
        }
    }
    func updateAccessibility() {
        item.button?.toolTip = "WorkHarbor · " + title("quickMenuHint")
        item.button?.setAccessibilityHelp(title("quickMenuHint"))
        item.button?.setAccessibilityCustomActions([
            NSAccessibilityCustomAction(name: title("openAgenda"), target: self, selector: #selector(accessibleAgenda)),
            NSAccessibilityCustomAction(name: title("quickOptions"), target: self, selector: #selector(accessibleOptions))
        ])
    }
    @objc private func buttonActivated(_ sender: NSStatusBarButton) { handleButtonEvent(NSApp.currentEvent) }
    /// The same rightMouseUp event is delivered for a configured trackpad secondary click.
    func handleButtonEvent(_ event: NSEvent?) {
        guard !invalidated else { return }
        let button: StatusItemMouseButton
        if event?.type == .rightMouseUp { button = .secondary }
        else if event?.type == .leftMouseUp { button = .primary }
        else if event?.type == .otherMouseUp || event?.type == .otherMouseDown { button = .other }
        else { button = .primary } // keyboard/AX press has no mouse event; preserve primary action.
        let control = event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true
        switch StatusMenuPolicy.intent(button: button, controlModified: control) {
        case .toggleAgenda: toggleAgenda()
        case .quickOptions: showQuickMenu()
        case .ignore: break
        }
    }
    func toggleAgenda() {
        guard !invalidated, !session.isOpen else { return }
        if popover.isShown || agendaRequested { closeAgenda() } else { showAgenda() }
    }
    func showAgenda() {
        guard !invalidated, item.button != nil else { return }
        updateAccessibility()
        guard !popover.isShown, !agendaRequested else { return }
        agendaRequested = true
        NSApp.activate(ignoringOtherApps: true)
        // Finish the input event and wait for activation before showing transient UI.
        // Otherwise the first activation can dismiss a just-created popover.
        DispatchQueue.main.async { [weak self] in self?.presentRequestedAgenda() }
    }
    private func presentRequestedAgenda() {
        guard agendaRequested, !invalidated, !session.isOpen, NSApp.isActive, let button=item.button else { return }
        agendaRequested = false
        let height = popover.contentViewController?.view.fittingSize.height ?? 620
        popover.contentSize = NSSize(width: 380, height: min(640, max(220, height)))
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    func closeAgenda() { agendaRequested = false; popover.performClose(nil) }
    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: title("quickOptions")); menu.autoenablesItems = false
        for action in StatusQuickAction.allCases {
            if action == .quit { menu.addItem(.separator()) }
            let key: String
            switch action { case .agenda: key="openAgenda"; case .settings:key="settings"; case .refresh:key="refresh"; case .quit:key="quit" }
            let entry = NSMenuItem(title: title(key), action: #selector(menuSelected(_:)), keyEquivalent: "")
            entry.identifier = NSUserInterfaceItemIdentifier(action.rawValue)
            entry.representedObject = action.rawValue; entry.target = self
            entry.isEnabled = action != .refresh || canRefresh()
            if action == .refresh && !entry.isEnabled { entry.toolTip = title("refreshUnavailable") }
            menu.addItem(entry)
        }
        return menu
    }
    func showQuickMenu() {
        guard !invalidated, let button = item.button, session.begin(canRefresh: canRefresh()) else { return }
        closeAgenda(); updateAccessibility()
        button.highlight(true)
        presentMenu(makeMenu(), button)
        button.highlight(false)
        // Nothing is called if the menu was opened and dismissed without selecting an item.
        guard let action = session.finish(), !invalidated else { return }
        switch action {
        case .agenda: showAgenda()
        case .settings: openSettings()
        case .refresh: if canRefresh() { refresh() }
        case .quit: quit()
        }
    }
    @objc private func menuSelected(_ sender: NSMenuItem) {
        guard sender.isEnabled, let raw=sender.representedObject as? String, let action=StatusQuickAction(rawValue:raw) else { return }
        session.select(action)
    }
    @objc func accessibleAgenda() -> Bool { guard !invalidated else { return false }; showAgenda(); return true }
    @objc func accessibleOptions() -> Bool { guard !invalidated else { return false }; showQuickMenu(); return true }
    func invalidate() {
        guard !invalidated else { return }
        closeAgenda(); invalidated = true
        if let activationObserver {NotificationCenter.default.removeObserver(activationObserver)}
        activationObserver=nil
        item.button?.target = nil
        item.button?.setAccessibilityCustomActions(nil)
        NSStatusBar.system.removeStatusItem(item)
    }
}
